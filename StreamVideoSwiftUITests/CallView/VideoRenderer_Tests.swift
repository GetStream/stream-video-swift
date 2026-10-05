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

    func test_add_sameTrack_attachesOnceOffMainThread() async throws {
        let factory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let track = factory.makeVideoTrack(
            source: factory.makeVideoSource(forScreenShare: false)
        )
        let selector = #selector(RTCVideoTrack.add(_:))
        let method = try XCTUnwrap(
            class_getInstanceMethod(RTCVideoTrack.self, selector)
        )
        let originalImplementation = method_getImplementation(method)
        let original = unsafeBitCast(
            originalImplementation,
            to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
        )
        let callsOnMainThread = Atomic(wrappedValue: [Bool]())
        let queueKey = DispatchSpecificKey<Bool>()
        subject.queue.setSpecific(key: queueKey, value: true)
        let replacement: @convention(block) (RTCVideoTrack, AnyObject) -> Void = { currentTrack, renderer in
            if currentTrack === track,
               Thread.isMainThread || DispatchQueue.getSpecific(key: queueKey) == true {
                callsOnMainThread.mutate { $0.append(Thread.isMainThread) }
            }
            original(currentTrack, selector, renderer)
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
            subject.queue.setSpecific(key: queueKey, value: nil)
        }

        subject.add(track: track)
        subject.add(track: track)
        await withCheckedContinuation { continuation in
            subject.queue.async { continuation.resume() }
        }

        XCTAssertEqual(callsOnMainThread.wrappedValue, [false])

        await withCheckedContinuation { [subject] continuation in
            subject!.queue.async {
                track.remove(subject!)
                continuation.resume()
            }
        }
    }

    nonisolated func test_add_blockedWebRTC_mainThreadRemainsResponsive() async throws {
        try await assertMainThreadResponsive(stallRemoval: false)
    }

    nonisolated func test_add_replacingTrack_blockedRemoval_mainThreadRemainsResponsive() async throws {
        try await assertMainThreadResponsive(stallRemoval: true)
    }

    nonisolated func test_dismantle_blockedRemoval_mainThreadRemainsResponsive() async throws {
        try await assertDismantleDuringBlockedRemoval()
    }

    func test_dismantle_reusedRenderer_doesNotDetachReplacement() async throws {
        try await assertRetiredCoordinatorDoesNotDetachReplacement(deallocate: false)
    }

    func test_deinit_reusedRenderer_doesNotDetachReplacement() async throws {
        try await assertRetiredCoordinatorDoesNotDetachReplacement(deallocate: true)
    }

    // MARK: - Private helpers

    private func assertRetiredCoordinatorDoesNotDetachReplacement(
        deallocate: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
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
        // Attachment and cleanup share a serial queue. Wait until the reused
        // renderer actually holds the replacement before retiring its owner.
        await withCheckedContinuation { continuation in
            reusedRenderer.queue.async { continuation.resume() }
        }

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
            reusedRenderer.removeTrack()
            VideoRendererPool.currentValue = originalPool
        }

        if deallocate {
            let coordinatorIsAlive = { [weak coordinator] in coordinator != nil }
            coordinator = nil
            XCTAssertFalse(coordinatorIsAlive(), file: file, line: line)
        } else {
            try XCTUnwrap(coordinator).dismantle()
        }
        // A stale cleanup could enqueue removal and return immediately. Drain
        // it before asserting so the test also covers queued detachment.
        await withCheckedContinuation { continuation in
            reusedRenderer.queue.async { continuation.resume() }
        }

        XCTAssertEqual(removals.wrappedValue, 0, "Old cleanup detached the replacement.", file: file, line: line)
        XCTAssertFalse(
            pool.acquireRenderer(size: .zero) === reusedRenderer,
            "An active renderer returned to the pool.",
            file: file,
            line: line
        )
    }

    private nonisolated func assertDismantleDuringBlockedRemoval(
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let track = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
        let selector = #selector(RTCVideoTrack.remove(_:))
        let method = try XCTUnwrap(class_getInstanceMethod(RTCVideoTrack.self, selector))
        let originalImplementation = method_getImplementation(method)
        let original = unsafeBitCast(
            originalImplementation,
            to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
        )
        let originalPool = await MainActor.run { VideoRendererPool.currentValue }
        let pool = await MainActor.run { VideoRendererPool(initialCapacity: 1) }
        let subject = await MainActor.run { pool.acquireRenderer(size: .zero) }
        let coordinator = Atomic<VideoRendererView.Coordinator?>(wrappedValue: nil)
        await MainActor.run {
            VideoRendererPool.currentValue = pool
            pool.releaseRenderer(subject)
            coordinator.wrappedValue = .init(handleRendering: nil)
            subject.add(track: track)
        }
        let rendererQueue = await MainActor.run { subject.queue }
        await withCheckedContinuation { continuation in
            rendererQueue.async { continuation.resume() }
        }
        let enteredRemoval = expectation(description: "Entered native dismantle removal")
        let finishedRemoval = expectation(description: "Native removal finished")
        let returnedFromDismantle = expectation(description: "View dismantle returned")
        let mainHeartbeat = expectation(description: "Main responded during dismantle")
        let releaseGate = DispatchSemaphore(value: 0)
        let didRemove = Atomic(wrappedValue: false)
        let gateTimedOut = Atomic(wrappedValue: false)
        let remove: @convention(block) (RTCVideoTrack, AnyObject) -> Void = { currentTrack, renderer in
            var intercept = false
            if currentTrack === track, renderer === subject {
                didRemove.mutate {
                    intercept = !$0
                    $0 = true
                }
            }
            if intercept {
                enteredRemoval.fulfill()
                gateTimedOut.wrappedValue = releaseGate.wait(timeout: .now() + 10) == .timedOut
            }
            original(currentTrack, selector, renderer)
            if intercept { finishedRemoval.fulfill() }
        }
        let implementation = imp_implementationWithBlock(remove)
        method_setImplementation(method, implementation)
        defer {
            releaseGate.signal()
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(implementation)
        }

        DispatchQueue.main.async {
            VideoRendererView.dismantleUIView(subject, coordinator: coordinator.wrappedValue!)
            returnedFromDismantle.fulfill()
        }
        await fulfillment(of: [enteredRemoval], timeout: 5)
        DispatchQueue.main.async { mainHeartbeat.fulfill() }
        let respondedDuringRemoval = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XCTWaiter.wait(for: [mainHeartbeat], timeout: 1)
                continuation.resume(returning: result == .completed)
            }
        }
        releaseGate.signal()
        await fulfillment(of: [finishedRemoval, returnedFromDismantle], timeout: 5)
        await withCheckedContinuation { continuation in
            rendererQueue.async { continuation.resume() }
        }
        let currentTrack = await MainActor.run { subject.track }
        await MainActor.run { coordinator.wrappedValue = nil }
        await withCheckedContinuation { continuation in
            rendererQueue.async {
                track.remove(subject)
                subject.track = nil
                continuation.resume()
            }
        }
        await MainActor.run { VideoRendererPool.currentValue = originalPool }

        XCTAssertTrue(
            respondedDuringRemoval,
            "Dismantle held the main thread until native removal finished.",
            file: file,
            line: line
        )
        XCTAssertFalse(gateTimedOut.wrappedValue, "Emergency removal timeout fired.", file: file, line: line)
        XCTAssertNil(currentTrack, "Dismantle must clear the stored track.", file: file, line: line)
    }

    private nonisolated func assertMainThreadResponsive(
        stallRemoval: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let track = factory.makeVideoTrack(
            source: factory.makeVideoSource(forScreenShare: false)
        )
        let replacementTrack = factory.makeVideoTrack(
            source: factory.makeVideoSource(forScreenShare: false)
        )
        let subject = await MainActor.run { VideoRenderer(frame: .zero) }
        let rendererQueue = await MainActor.run { subject.queue }
        if stallRemoval {
            await MainActor.run { subject.add(track: track) }
            await withCheckedContinuation { continuation in
                rendererQueue.async { continuation.resume() }
            }
        }
        let enteredWebRTC = expectation(description: "Entered gated renderer operation")
        let returnedFromWebRTC = expectation(description: "Finished gated renderer operation")
        let returnedFromAdd = expectation(description: "Renderer add returned")
        let mainHeartbeat = expectation(description: "Main thread responded during stall")
        let releaseGate = DispatchSemaphore(value: 0)
        let didIntercept = Atomic(wrappedValue: false)
        let gateTimedOut = Atomic(wrappedValue: false)
        let selector = stallRemoval
            ? #selector(RTCVideoTrack.remove(_:))
            : #selector(RTCVideoTrack.add(_:))
        let method = try XCTUnwrap(
            class_getInstanceMethod(RTCVideoTrack.self, selector)
        )
        let originalImplementation = method_getImplementation(method)
        let original = unsafeBitCast(
            originalImplementation,
            to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
        )
        let replacement: @convention(block) (RTCVideoTrack, AnyObject) -> Void = { currentTrack, renderer in
            var shouldBlock = false
            if currentTrack === track, renderer === subject {
                didIntercept.mutate {
                    shouldBlock = !$0
                    $0 = true
                }
            }
            if shouldBlock {
                enteredWebRTC.fulfill()
                let didTimeOut = releaseGate.wait(timeout: .now() + 10) == .timedOut
                gateTimedOut.mutate { $0 = didTimeOut }
            }
            original(currentTrack, selector, renderer)
            if shouldBlock { returnedFromWebRTC.fulfill() }
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            releaseGate.signal()
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
        }

        DispatchQueue.main.async {
            subject.add(track: stallRemoval ? replacementTrack : track)
            returnedFromAdd.fulfill()
        }
        await fulfillment(of: [enteredWebRTC], timeout: 5)
        DispatchQueue.main.async { mainHeartbeat.fulfill() }

        let mainRespondedDuringStall = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XCTWaiter.wait(for: [mainHeartbeat], timeout: 1)
                continuation.resume(returning: result == .completed)
            }
        }

        releaseGate.signal()
        await fulfillment(of: [returnedFromWebRTC, returnedFromAdd], timeout: 5)
        // Removal finishes before replacement attachment. Drain the renderer's
        // queue so cleanup cannot race that attachment in the async control.
        await withCheckedContinuation { continuation in
            rendererQueue.async { continuation.resume() }
        }
        await MainActor.run {
            track.remove(subject)
            replacementTrack.remove(subject)
        }

        XCTAssertTrue(
            mainRespondedDuringStall,
            "Main thread could not respond while \(NSStringFromSelector(selector)) was blocked.",
            file: file,
            line: line
        )
        XCTAssertFalse(
            gateTimedOut.wrappedValue,
            "The emergency gate timeout fired.",
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
