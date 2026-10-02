//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Dispatch
import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MediaFrameReporter_StallTests: XCTestCase, @unchecked Sendable {

    private enum Detachment {
        case remove, removeAll, reset, firstFrame
    }

    func test_remove_video_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .video, action: .remove)
    }

    func test_remove_audio_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .audio, action: .remove)
    }

    func test_removeAll_video_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .video, action: .removeAll)
    }

    func test_removeAll_audio_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .audio, action: .removeAll)
    }

    func test_reset_video_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .video, action: .reset)
    }

    func test_reset_audio_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .audio, action: .reset)
    }

    func test_firstFrame_video_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .video, action: .firstFrame)
    }

    func test_firstFrame_audio_blockedNativeCall_keepsMainAndCooperativePoolFree() async throws {
        try await assertDetachmentDoesNotBlockSharedThreads(type: .audio, action: .firstFrame)
    }

    private func assertDetachmentDoesNotBlockSharedThreads(
        type: TrackType,
        action: Detachment,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.mock()
        let track = makeTrack(factory: factory, type: type)
        let eventReporter = MockClientEventReporter()
        let subject = MediaFrameReporter(clientEventReporter: eventReporter)
        await subject.add(track, type: type)
        let enteredRemoval = expectation(description: "Entered first-frame renderer removal")
        let mainHeartbeat = expectation(description: "Main responded during first-frame removal")
        let releaseGate = DispatchSemaphore(value: 0)
        let didIntercept = Atomic(wrappedValue: false)
        let gateTimedOut = Atomic(wrappedValue: false)
        let entryQueue = Atomic(wrappedValue: "")
        let trackClass: AnyClass = type == .audio ? RTCAudioTrack.self : RTCVideoTrack.self
        let selector = NSSelectorFromString("removeRenderer:")
        let method = try XCTUnwrap(class_getInstanceMethod(trackClass, selector))
        let originalIMP = method_getImplementation(method)
        let original = unsafeBitCast(originalIMP, to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self)
        let replacement: @convention(block) (RTCMediaStreamTrack, AnyObject) -> Void = { currentTrack, renderer in
            var intercept = false
            if currentTrack === track {
                didIntercept.mutate {
                    intercept = !$0
                    $0 = true
                }
            }
            if intercept {
                entryQueue.wrappedValue = String(cString: __dispatch_queue_get_label(nil))
                enteredRemoval.fulfill()
                gateTimedOut.wrappedValue = releaseGate.wait(timeout: .now() + 10) == .timedOut
            }
            original(currentTrack, selector, renderer)
        }
        let replacementIMP = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementIMP)
        defer {
            releaseGate.signal()
            method_setImplementation(method, originalIMP)
            imp_removeBlock(replacementIMP)
        }

        let removal = Task {
            switch action {
            case .remove: await subject.remove(track, type: type)
            case .removeAll: await subject.removeAllTracks()
            case .reset: await subject.reset(details: .init(callSessionId: "new-session"))
            case .firstFrame: await subject.reportFrame(type: type, trackId: track.trackId)
            }
        }
        await fulfillment(of: [enteredRemoval], timeout: 5)
        DispatchQueue.main.async { mainHeartbeat.fulfill() }
        let mainResponded = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XCTWaiter.wait(for: [mainHeartbeat], timeout: 1)
                continuation.resume(returning: result == .completed)
            }
        }
        releaseGate.signal()
        await removal.value
        await subject.removeAllTracks()
        let queue = entryQueue.wrappedValue

        XCTAssertTrue(mainResponded, "First-frame detachment blocked main.", file: file, line: line)
        XCTAssertFalse(queue.isEmpty, "The native method must be intercepted.", file: file, line: line)
        XCTAssertFalse(
            queue.contains("cooperative"),
            "Blocked detachment occupied a cooperative executor thread: \(queue)",
            file: file,
            line: line
        )
        XCTAssertNotEqual(queue, "com.apple.main-thread", file: file, line: line)
        XCTAssertFalse(gateTimedOut.wrappedValue, "Emergency detachment timeout fired.", file: file, line: line)
        if action == .firstFrame {
            let events = await eventReporter.reportedEvents
            XCTAssertEqual(events.count, 1, file: file, line: line)
            XCTAssertEqual(events.first?.details.trackId, track.trackId, file: file, line: line)
        }
    }

    private func makeTrack(factory: PeerConnectionFactory, type: TrackType) -> RTCMediaStreamTrack {
        type == .audio
            ? factory.mockAudioTrack()
            : factory.mockVideoTrack(forScreenShare: false)
    }
}
