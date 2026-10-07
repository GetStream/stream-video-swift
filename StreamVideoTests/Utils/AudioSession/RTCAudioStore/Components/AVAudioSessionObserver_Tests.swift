//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import ObjectiveC
import StreamSwiftTestHelpers
@testable import StreamVideo
import XCTest

final class AVAudioSessionObserver_Tests: XCTestCase, @unchecked Sendable {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func test_snapshot_renderingModeIsEmpty() {
        XCTAssertEqual(AVAudioSession.Snapshot().renderingMode, "")
    }

    #if compiler(>=6.1)
    func test_snapshot_iOSAppOnMac_doesNotReadEchoCancellation() throws {
        try assertEchoCancellationSnapshot(
            isIOSAppOnMac: true,
            isMacCatalystApp: false
        )
    }

    func test_snapshot_macCatalyst_doesNotReadEchoCancellation() throws {
        try assertEchoCancellationSnapshot(
            isIOSAppOnMac: false,
            isMacCatalystApp: true
        )
    }

    func test_snapshot_iOS_readsEchoCancellation() throws {
        try assertEchoCancellationSnapshot(
            isIOSAppOnMac: false,
            isMacCatalystApp: false
        )
    }
    #endif

    func test_startObserving_emitsSnapshotsFromTimer() async {
        let observer = AVAudioSessionObserver()
        let expectation = expectation(description: "snapshots")
        expectation.expectedFulfillmentCount = 2

        observer.publisher
            .prefix(2)
            .sink { snapshot in
                XCTAssertEqual(snapshot.category, AVAudioSession.sharedInstance().category)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        observer.startObserving()

        await fulfillment(of: [expectation], timeout: 1)
        observer.stopObserving()
    }

    func test_stopObserving_preventsFurtherEmissions() async throws {
        try XCTSkipIf(
            TestRunnerEnvironment.isCI,
            "https://linear.app/stream/issue/IOS-1326/cifix-failing-test-on-ios-15-and-16-only-which-passes-locally"
        )
        let observer = AVAudioSessionObserver()
        let firstTwo = expectation(description: "first snapshots")
        let noMoreSnapshots = expectation(description: "no extra snapshots")
        noMoreSnapshots.isInverted = true

        observer.publisher
            .prefix(2)
            .sink(
                receiveCompletion: { _ in firstTwo.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        observer.publisher
            .dropFirst(2)
            .sink { _ in noMoreSnapshots.fulfill() }
            .store(in: &cancellables)

        observer.startObserving()
        await fulfillment(of: [firstTwo], timeout: 1)

        observer.stopObserving()
        await fulfillment(of: [noMoreSnapshots], timeout: 0.3)
    }

    // MARK: - Private Helpers

    #if compiler(>=6.1)
    private func assertEchoCancellationSnapshot(
        isIOSAppOnMac: Bool,
        isMacCatalystApp: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Requires iOS 18.2 or later.")
        }

        let processInfoClass = try XCTUnwrap(object_getClass(ProcessInfo.processInfo))
        let audioSessionClass = try XCTUnwrap(object_getClass(AVAudioSession.sharedInstance()))
        let getters: [(AnyClass, String, Bool)] = [
            (processInfoClass, "isiOSAppOnMac", isIOSAppOnMac),
            (processInfoClass, "isMacCatalystApp", isMacCatalystApp),
            (audioSessionClass, "prefersEchoCancelledInput", true),
            (audioSessionClass, "isEchoCancelledInputEnabled", true),
            (audioSessionClass, "isEchoCancelledInputAvailable", true)
        ]
        let reads = Atomic(wrappedValue: 0)
        var replacements: [(Method, IMP, IMP)] = []
        defer {
            for (method, original, replacement) in replacements.reversed() {
                method_setImplementation(method, original)
                imp_removeBlock(replacement)
            }
        }

        for (type, name, value) in getters {
            let method = try XCTUnwrap(
                class_getInstanceMethod(type, NSSelectorFromString(name))
            )
            let original = method_getImplementation(method)
            let getter: @convention(block) (AnyObject) -> Bool = { _ in
                if type == audioSessionClass {
                    reads.mutate { $0 += 1 }
                }
                return value
            }
            let replacement = imp_implementationWithBlock(getter)
            replacements.append((method, original, replacement))
            method_setImplementation(method, replacement)
        }

        XCTAssertEqual(ProcessInfo.processInfo.isiOSAppOnMac, isIOSAppOnMac, file: file, line: line)
        XCTAssertEqual(ProcessInfo.processInfo.isMacCatalystApp, isMacCatalystApp, file: file, line: line)
        let subject = AVAudioSession.Snapshot()
        let expected = !isIOSAppOnMac && !isMacCatalystApp

        XCTAssertEqual(subject.prefersEchoCancelledInput, expected, file: file, line: line)
        XCTAssertEqual(subject.isEchoCancelledInputEnabled, expected, file: file, line: line)
        XCTAssertEqual(subject.isEchoCancelledInputAvailable, expected, file: file, line: line)
        XCTAssertEqual(reads.wrappedValue, expected ? 3 : 0, file: file, line: line)
        XCTAssertEqual(subject.category, AVAudioSession.sharedInstance().category, file: file, line: line)
    }
    #endif
}
