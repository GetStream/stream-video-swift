//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class WebRTCEventLogging_StallTests: XCTestCase, @unchecked Sendable {

    private enum Events {
        case stream, receiver, track
    }

    func test_streamEventDescriptions_gatedTrackLists_doNotBlockMain() async throws {
        try await assertDescriptionsAvoidNativeGetters(events: .stream)
    }

    func test_receiverEventDescriptions_gatedTrackAndParameters_doNotBlockMain() async throws {
        try await assertDescriptionsAvoidNativeGetters(events: .receiver)
    }

    func test_trackEventDescriptions_gatedStateAndEnabled_doNotBlockMain() async throws {
        try await assertDescriptionsAvoidNativeGetters(events: .track)
    }

    // Keep non-Sendable WebRTC fixtures on the actor that formats the events.
    @MainActor
    private func assertDescriptionsAvoidNativeGetters(
        events: Events,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.mock()
        let stream = factory.mockMediaStream()
        let track = factory.mockVideoTrack(forScreenShare: false)
        stream.addVideoTrack(track)
        let connection = try factory.makePeerConnection(configuration: .init(), constraints: .defaultConstraints, delegate: nil)
        let receiver = try XCTUnwrap(connection.addTransceiver(of: .video)).receiver
        let parameters = receiver.parameters
        let receiverTrack = receiver.track
        let finishedFormatting = expectation(description: "Event formatting returned on main")
        let releaseGate = DispatchSemaphore(value: 0)
        let nativeReads = Atomic(wrappedValue: [String]())
        let didBlock = Atomic(wrappedValue: false)
        let gateTimedOut = Atomic(wrappedValue: false)
        let descriptions = Atomic(wrappedValue: [String]())
        let recordRead: (String) -> Void = { getter in
            nativeReads.mutate { $0.append(getter) }
            var shouldBlock = false
            didBlock.mutate {
                shouldBlock = !$0
                $0 = true
            }
            if shouldBlock {
                gateTimedOut.wrappedValue = releaseGate.wait(timeout: .now() + 10) == .timedOut
            }
        }
        let objectGetters: [(AnyClass, Selector, AnyObject?)]
        switch events {
        case .stream:
            objectGetters = [
                (RTCMediaStream.self, #selector(getter: RTCMediaStream.audioTracks), NSArray()),
                (RTCMediaStream.self, #selector(getter: RTCMediaStream.videoTracks), NSArray())
            ]
        case .receiver:
            objectGetters = [
                (RTCRtpReceiver.self, #selector(getter: RTCRtpReceiver.track), receiverTrack),
                (RTCRtpReceiver.self, #selector(getter: RTCRtpReceiver.parameters), parameters)
            ]
        case .track:
            objectGetters = []
        }
        var interceptedMethods: [(Method, IMP, IMP)] = []
        defer {
            releaseGate.signal()
            for (method, original, replacement) in interceptedMethods {
                method_setImplementation(method, original)
                imp_removeBlock(replacement)
            }
            connection.close()
        }
        for getter in objectGetters {
            let type: AnyClass = getter.0
            let selector = getter.1
            let value = getter.2
            let method = try XCTUnwrap(class_getInstanceMethod(type, selector))
            let original = method_getImplementation(method)
            let replacement: @convention(block) (AnyObject) -> AnyObject? = { _ in
                recordRead(NSStringFromSelector(selector))
                return value
            }
            let implementation = imp_implementationWithBlock(replacement)
            interceptedMethods.append((method, original, implementation))
            method_setImplementation(method, implementation)
        }
        if events == .track {
            let stateSelector = #selector(getter: RTCMediaStreamTrack.readyState)
            let stateMethod = try XCTUnwrap(class_getInstanceMethod(RTCMediaStreamTrack.self, stateSelector))
            let state: @convention(block) (AnyObject) -> Int = { _ in
                recordRead("readyState")
                return 0
            }
            let stateIMP = imp_implementationWithBlock(state)
            interceptedMethods.append((stateMethod, method_getImplementation(stateMethod), stateIMP))
            method_setImplementation(stateMethod, stateIMP)
            let enabledSelector = #selector(getter: RTCMediaStreamTrack.isEnabled)
            let enabledMethod = try XCTUnwrap(class_getInstanceMethod(RTCMediaStreamTrack.self, enabledSelector))
            let enabled: @convention(block) (AnyObject) -> Bool = { _ in
                recordRead("isEnabled")
                return true
            }
            let enabledIMP = imp_implementationWithBlock(enabled)
            interceptedMethods.append((enabledMethod, method_getImplementation(enabledMethod), enabledIMP))
            method_setImplementation(enabledMethod, enabledIMP)
        }
        DispatchQueue.main.async {
            let values: [String]
            switch events {
            case .stream:
                values = [
                    String(describing: StreamRTCPeerConnection.AddedStreamEvent(stream: stream)),
                    String(describing: StreamRTCPeerConnection.RemovedStreamEvent(stream: stream))
                ]
            case .receiver:
                values = [
                    String(describing: StreamRTCPeerConnection.AddedReceiverEvent(receiver: receiver, streams: [stream])),
                    String(describing: StreamRTCPeerConnection.DidAddReceiverEvent(receiver: receiver, streams: [stream])),
                    String(describing: StreamRTCPeerConnection.RemovedReceiverEvent(receiver: receiver)),
                    String(describing: StreamRTCPeerConnection.DidRemoveReceiverEvent(receiver: receiver))
                ]
            case .track:
                values = [
                    String(describing: TrackEvent.added(id: track.trackId, trackType: .video, track: track)),
                    String(describing: TrackEvent.removed(id: track.trackId, trackType: .video, track: track))
                ]
            }
            descriptions.wrappedValue = values
            finishedFormatting.fulfill()
        }
        let returnedWithoutReadingBlockedState = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XCTWaiter.wait(for: [finishedFormatting], timeout: 1)
                releaseGate.signal()
                continuation.resume(returning: result == .completed)
            }
        }
        await MainActor.run {}

        XCTAssertTrue(returnedWithoutReadingBlockedState, "Formatting waited for gated WebRTC state.", file: file, line: line)
        XCTAssertEqual(nativeReads.wrappedValue, [], "Event descriptions read synchronized getters.", file: file, line: line)
        XCTAssertFalse(descriptions.wrappedValue.isEmpty, file: file, line: line)
        XCTAssertFalse(gateTimedOut.wrappedValue, "Emergency getter timeout fired.", file: file, line: line)
    }
}
