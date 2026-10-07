//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Dispatch
import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamRTCPeerConnection_StallTests: XCTestCase, @unchecked Sendable {

    func test_close_blockedEntry_cancelsQueuedWorkAndStopsBeforeClosingOnce() async throws {
        try await assertCloseWithBlockedEntry(blockedOffer: false)
    }

    func test_close_blockedSDPEntry_cancelsQueuedWorkAndStopsBeforeClosingOnce() async throws {
        try await assertCloseWithBlockedEntry(blockedOffer: true)
    }

    private func assertCloseWithBlockedEntry(
        blockedOffer: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.mock()
        let subject = try StreamRTCPeerConnection(factory, configuration: RTCConfiguration())
        let track = factory.mockVideoTrack(forScreenShare: false)
        _ = try XCTUnwrap(subject.addTransceiver(trackType: .video, with: track, init: .init()))
        let enteredOperation = expectation(description: "First operation entered native API")
        let pendingStarted = expectation(description: "Pending operation started")
        let pendingEnteredNative = expectation(description: "Pending operation entered native API")
        pendingEnteredNative.isInverted = true
        let finishedClose = expectation(description: "Native close completed")
        let releaseGate = DispatchSemaphore(value: 0)
        let gateTimedOut = Atomic(wrappedValue: false)
        let nativeConnection = Atomic<RTCPeerConnection?>(wrappedValue: nil)
        let nativeCalls = Atomic(wrappedValue: 0)
        let teardown = Atomic(wrappedValue: [String]())
        let operationSelector = NSSelectorFromString(
            blockedOffer
                ? "offerForConstraints:completionHandler:"
                : "statisticsWithCompletionHandler:"
        )
        let stopSelector = #selector(RTCRtpTransceiver.stopInternal)
        let closeSelector = #selector(RTCPeerConnection.close)
        let operationMethod = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, operationSelector))
        let stopMethod = try XCTUnwrap(class_getInstanceMethod(RTCRtpTransceiver.self, stopSelector))
        let closeMethod = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, closeSelector))
        let operationIMP = method_getImplementation(operationMethod)
        let stopIMP = method_getImplementation(stopMethod)
        let closeIMP = method_getImplementation(closeMethod)
        let originalStatistics = unsafeBitCast(operationIMP, to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self)
        typealias TeardownMethod = @convention(c) (AnyObject, Selector) -> Void
        let originalStop = unsafeBitCast(stopIMP, to: TeardownMethod.self)
        let originalClose = unsafeBitCast(closeIMP, to: TeardownMethod.self)
        let enterOperation: @Sendable (RTCPeerConnection) -> Void = { connection in
            var callNumber = 0
            nativeCalls.mutate {
                $0 += 1
                callNumber = $0
            }
            if callNumber == 1 {
                nativeConnection.wrappedValue = connection
                enteredOperation.fulfill()
                gateTimedOut.wrappedValue = releaseGate.wait(timeout: .now() + 10) == .timedOut
            } else if callNumber == 2 {
                pendingEnteredNative.fulfill()
            }
        }
        let statistics: @convention(block) (RTCPeerConnection, AnyObject) -> Void = { connection, completion in
            enterOperation(connection)
            originalStatistics(connection, operationSelector, completion)
        }
        let originalOffer = unsafeBitCast(
            operationIMP,
            to: (@convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void).self
        )
        let offer: @convention(block) (RTCPeerConnection, AnyObject, AnyObject) -> Void = { connection, constraints, completion in
            enterOperation(connection)
            originalOffer(connection, operationSelector, constraints, completion)
        }
        let stop: @convention(block) (RTCRtpTransceiver) -> Void = { transceiver in
            teardown.mutate { $0.append("stop") }
            originalStop(transceiver, stopSelector)
        }
        let close: @convention(block) (RTCPeerConnection) -> Void = { connection in
            originalClose(connection, closeSelector)
            if connection === nativeConnection.wrappedValue {
                var isFirstClose = false
                teardown.mutate {
                    isFirstClose = !$0.contains("close")
                    $0.append("close")
                }
                if isFirstClose { finishedClose.fulfill() }
            }
        }
        let replacements = [
            blockedOffer ? imp_implementationWithBlock(offer) : imp_implementationWithBlock(statistics),
            imp_implementationWithBlock(stop),
            imp_implementationWithBlock(close)
        ]
        method_setImplementation(operationMethod, replacements[0])
        method_setImplementation(stopMethod, replacements[1])
        method_setImplementation(closeMethod, replacements[2])
        defer {
            releaseGate.signal()
            method_setImplementation(operationMethod, operationIMP)
            method_setImplementation(stopMethod, stopIMP)
            method_setImplementation(closeMethod, closeIMP)
            replacements.forEach { imp_removeBlock($0) }
        }

        @Sendable func performOperation() async throws {
            if blockedOffer {
                _ = try await subject.offer(for: .defaultConstraints)
            } else {
                _ = try await subject.statistics()
            }
        }
        let running = Task {
            do {
                try await performOperation()
                return true
            } catch {
                return false
            }
        }
        await fulfillment(of: [enteredOperation], timeout: 5)
        let pending = Task {
            pendingStarted.fulfill()
            do {
                try await performOperation()
                return false
            } catch {
                return error is CancellationError
            }
        }
        await fulfillment(of: [pendingStarted], timeout: 5)
        let keptPendingOutsideWebRTC = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XCTWaiter.wait(for: [pendingEnteredNative], timeout: 1)
                continuation.resume(returning: result == .completed)
            }
        }
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 { group.addTask { await subject.close() } }
        }
        releaseGate.signal()
        let runningSucceeded = await running.value
        if !blockedOffer { XCTAssertTrue(runningSucceeded, file: file, line: line) }
        let cancelledPending = await pending.value
        await fulfillment(of: [finishedClose], timeout: 5)
        await MainActor.run {}
        do {
            try await performOperation()
            XCTFail("Operations submitted after close must be cancelled.", file: file, line: line)
        } catch {
            XCTAssertTrue(error is CancellationError, file: file, line: line)
        }

        XCTAssertTrue(
            keptPendingOutsideWebRTC,
            "The second operation reached WebRTC while the first entry was blocked.",
            file: file,
            line: line
        )
        XCTAssertTrue(cancelledPending, "Work waiting at close must fail with CancellationError.", file: file, line: line)
        XCTAssertEqual(nativeCalls.wrappedValue, 1, file: file, line: line)
        XCTAssertEqual(teardown.wrappedValue, ["stop", "close"], file: file, line: line)
        XCTAssertFalse(gateTimedOut.wrappedValue, "Emergency native entry timeout fired.", file: file, line: line)
    }

    func test_offer_completionAfterClose_doesNotEnterSetLocalDescription() async throws {
        try await assertLateOfferCompletionIsDiscarded()
    }

    private func assertLateOfferCompletionIsDiscarded(
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.mock()
        let subject = try StreamRTCPeerConnection(factory, configuration: .init())
        let nativeCompleted = expectation(description: "Real native completion held")
        let nativeClosed = expectation(description: "Native close finished before completion release")
        let releaseCompletion = Atomic<(() -> Void)?>(wrappedValue: nil)
        let nativeSucceeded = Atomic(wrappedValue: false)
        let nativeConnection = Atomic<RTCPeerConnection?>(wrappedValue: nil)
        let setLocalCalls = Atomic(wrappedValue: 0)
        let selector = NSSelectorFromString("offerForConstraints:completionHandler:")
        let method = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, selector))
        let closeSelector = #selector(RTCPeerConnection.close)
        let closeMethod = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, closeSelector))
        let localSelector = NSSelectorFromString("setLocalDescription:completionHandler:")
        let localMethod = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, localSelector))
        let originalIMP = method_getImplementation(method)
        let closeIMP = method_getImplementation(closeMethod)
        let localIMP = method_getImplementation(localMethod)
        typealias DescriptionMethod = @convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void
        let original = unsafeBitCast(originalIMP, to: DescriptionMethod.self)
        let originalLocal = unsafeBitCast(localIMP, to: DescriptionMethod.self)
        let originalClose = unsafeBitCast(closeIMP, to: (@convention(c) (AnyObject, Selector) -> Void).self)
        let replacement: @convention(block) (RTCPeerConnection, AnyObject, AnyObject) -> Void = { connection, input, callback in
            nativeConnection.wrappedValue = connection
            let completion = unsafeBitCast(callback, to: (@convention(block) (RTCSessionDescription?, NSError?) -> Void).self)
            let held: @convention(block) (RTCSessionDescription?, NSError?) -> Void = { description, error in
                nativeSucceeded.wrappedValue = description != nil && error == nil
                releaseCompletion.wrappedValue = { completion(description, error) }
                nativeCompleted.fulfill()
            }
            original(connection, selector, input, held as AnyObject)
        }
        let local: @convention(block) (RTCPeerConnection, AnyObject, AnyObject) -> Void = { connection, input, callback in
            if connection === nativeConnection.wrappedValue {
                setLocalCalls.mutate { $0 += 1 }
            }
            originalLocal(connection, localSelector, input, callback)
        }
        let close: @convention(block) (RTCPeerConnection) -> Void = { connection in
            originalClose(connection, closeSelector)
            if connection === nativeConnection.wrappedValue { nativeClosed.fulfill() }
        }
        let replacements = [
            imp_implementationWithBlock(replacement),
            imp_implementationWithBlock(local),
            imp_implementationWithBlock(close)
        ]
        method_setImplementation(method, replacements[0])
        method_setImplementation(localMethod, replacements[1])
        method_setImplementation(closeMethod, replacements[2])
        defer {
            method_setImplementation(method, originalIMP)
            method_setImplementation(localMethod, localIMP)
            method_setImplementation(closeMethod, closeIMP)
            replacements.forEach { imp_removeBlock($0) }
        }

        let operation = Task {
            do {
                let description = try await subject.offer(for: .defaultConstraints)
                try await subject.setLocalDescription(description)
                return false
            } catch {
                return error is CancellationError
            }
        }
        await fulfillment(of: [nativeCompleted], timeout: 5)
        XCTAssertTrue(nativeSucceeded.wrappedValue, "The held completion must be a real native success.", file: file, line: line)
        await subject.close()
        await fulfillment(of: [nativeClosed], timeout: 5)
        let completion = try XCTUnwrap(releaseCompletion.wrappedValue)
        releaseCompletion.wrappedValue = nil
        completion()
        let wasCancelled = await operation.value

        XCTAssertTrue(wasCancelled, "Late completion must not continue closed-connection work.", file: file, line: line)
        XCTAssertEqual(setLocalCalls.wrappedValue, 0, file: file, line: line)
    }

    func test_close_blockedWebRTC_mainThreadRemainsResponsive() async throws {
        let factory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let subject = try StreamRTCPeerConnection(
            factory,
            configuration: RTCConfiguration()
        )
        let enteredWebRTC = expectation(description: "Entered native close")
        let returnedFromWebRTC = expectation(description: "Finished native close")
        let mainHeartbeat = expectation(description: "Main thread responded during close")
        let releaseGate = DispatchSemaphore(value: 0)
        let didIntercept = Atomic(wrappedValue: false)
        let gateTimedOut = Atomic(wrappedValue: false)
        let selector = #selector(RTCPeerConnection.close)
        let method = try XCTUnwrap(
            class_getInstanceMethod(RTCPeerConnection.self, selector)
        )
        let originalImplementation = method_getImplementation(method)
        let original = unsafeBitCast(
            originalImplementation,
            to: (@convention(c) (AnyObject, Selector) -> Void).self
        )
        // Run this suite without parallel testing: the wrapper owns its native
        // connection privately, so the first close is intercepted globally.
        let replacement: @convention(block) (RTCPeerConnection) -> Void = { connection in
            var shouldBlock = false
            didIntercept.mutate {
                shouldBlock = !$0
                $0 = true
            }
            if shouldBlock {
                enteredWebRTC.fulfill()
                let didTimeOut = releaseGate.wait(timeout: .now() + 10) == .timedOut
                gateTimedOut.mutate { $0 = didTimeOut }
            }
            original(connection, selector)
            if shouldBlock { returnedFromWebRTC.fulfill() }
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            releaseGate.signal()
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
        }

        // Gate the native method's entry, not a delayed completion callback.
        // The async driver remains available to release it while main is held.
        await subject.close()
        await fulfillment(of: [enteredWebRTC], timeout: 5)
        DispatchQueue.main.async { mainHeartbeat.fulfill() }
        let mainRespondedDuringStall = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XCTWaiter.wait(for: [mainHeartbeat], timeout: 1)
                continuation.resume(returning: result == .completed)
            }
        }

        releaseGate.signal()
        await fulfillment(of: [returnedFromWebRTC], timeout: 5)
        await MainActor.run { withExtendedLifetime(subject) {} }

        XCTAssertTrue(
            mainRespondedDuringStall,
            "Main thread could not respond while RTCPeerConnection.close was blocked."
        )
        XCTAssertFalse(gateTimedOut.wrappedValue, "The emergency gate timeout fired.")
    }
}
