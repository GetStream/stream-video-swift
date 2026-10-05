//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import ObjectiveC
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

@MainActor
final class VideoRenderer_Tests: XCTestCase, @unchecked Sendable {

    private lazy var thermalStateSubject: PassthroughSubject<ProcessInfo.ThermalState, Never>! = .init()
    private lazy var mockThermalStateObserver: MockThermalStateObserver! = .init()
    private lazy var maximumFramesPerSecond: Int! = UIScreen.main.maximumFramesPerSecond
    private lazy var subject: VideoRenderer! = .init(frame: .zero)

    override func tearDown() async throws {
        InjectedValues[\.thermalStateObserver] = ThermalStateObserver { .nominal }
        thermalStateSubject = nil
        mockThermalStateObserver = nil
        maximumFramesPerSecond = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - preferredFramesPerSecond

    func testFPSForNominalThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .nominal,
            expected: Double(maximumFramesPerSecond)
        )
    }

    func testFPSForFairThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .fair,
            expected: Double(maximumFramesPerSecond)
        )
    }

    func testFPSForSeriousThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .serious,
            expected: Double(maximumFramesPerSecond) * 0.5
        )
    }

    func testFPSForCriticalThermalState() async {
        await assertPreferredFramesPerSecond(
            thermalState: .critical,
            expected: Double(maximumFramesPerSecond) * 0.4
        )
    }

    func test_handleViewRendering_trackEnabledStateWasNotRead() throws {
        let originalLogLevel = LogConfig.level
        LogConfig.level = .info
        defer { LogConfig.level = originalLogLevel }

        let factory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let track = factory.makeVideoTrack(
            source: factory.makeVideoSource(forScreenShare: false)
        )
        let participant = CallParticipant.dummy(track: track)
        let selector = #selector(getter: RTCMediaStreamTrack.isEnabled)
        let method = try XCTUnwrap(
            class_getInstanceMethod(RTCMediaStreamTrack.self, selector)
        )
        let originalImplementation = method_getImplementation(method)
        var wasRead = false
        let replacement: @convention(block) (RTCMediaStreamTrack) -> Bool = { _ in
            wasRead = true
            return true
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
        }

        subject.handleViewRendering(for: participant) { _, _ in }

        XCTAssertFalse(wasRead)
    }

    func test_dismantle_reusedRenderer_doesNotDetachReplacement() throws {
        try assertRetiredCoordinatorDoesNotDetachReplacement(deallocate: false)
    }

    func test_deinit_reusedRenderer_doesNotDetachReplacement() throws {
        try assertRetiredCoordinatorDoesNotDetachReplacement(deallocate: true)
    }

    // MARK: - Private helpers

    private func assertRetiredCoordinatorDoesNotDetachReplacement(
        deallocate: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let originalPool = VideoRendererPool.currentValue
        let pool = VideoRendererPool(initialCapacity: 1)
        subject = pool.acquireRenderer(size: .zero)
        pool.releaseRenderer(subject)
        VideoRendererPool.currentValue = pool
        var coordinator: VideoRendererView.Coordinator? = .init(handleRendering: nil)
        let factory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let track = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
        let replacement = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
        subject.add(track: track)
        try XCTUnwrap(coordinator).dismantle()
        let reusedRenderer = pool.acquireRenderer(size: .zero)
        XCTAssertTrue(reusedRenderer === subject, file: file, line: line)
        reusedRenderer.add(track: replacement)

        let selector = #selector(RTCVideoTrack.remove(_:))
        let method = try XCTUnwrap(class_getInstanceMethod(RTCVideoTrack.self, selector))
        let originalIMP = method_getImplementation(method)
        let original = unsafeBitCast(
            originalIMP,
            to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
        )
        let removals = Atomic(wrappedValue: 0)
        let intercept: @convention(block) (RTCVideoTrack, AnyObject) -> Void = { track, renderer in
            if track === replacement, renderer === reusedRenderer {
                removals.mutate { $0 += 1 }
            }
            original(track, selector, renderer)
        }
        let interceptIMP = imp_implementationWithBlock(intercept)
        method_setImplementation(method, interceptIMP)
        defer {
            method_setImplementation(method, originalIMP)
            imp_removeBlock(interceptIMP)
            coordinator = nil
            replacement.remove(reusedRenderer)
            VideoRendererPool.currentValue = originalPool
        }

        if deallocate {
            let coordinatorIsAlive = { [weak coordinator] in coordinator != nil }
            coordinator = nil
            XCTAssertFalse(coordinatorIsAlive(), file: file, line: line)
        } else {
            try XCTUnwrap(coordinator).dismantle()
        }

        XCTAssertEqual(removals.wrappedValue, 0, "Old cleanup detached the replacement.", file: file, line: line)
        XCTAssertFalse(
            pool.acquireRenderer(size: .zero) === reusedRenderer,
            "An active renderer returned to the pool.",
            file: file,
            line: line
        )
    }

    private func assertPreferredFramesPerSecond(
        thermalState: ProcessInfo.ThermalState,
        expected: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        mockThermalStateObserver.stub(
            for: \.statePublisher,
            with: thermalStateSubject.eraseToAnyPublisher()
        )
        _ = subject
        thermalStateSubject.send(thermalState)

        await fulfilmentInMainActor { [subject] in
            subject?.preferredFramesPerSecond == Int(expected)
        }
    }
}
