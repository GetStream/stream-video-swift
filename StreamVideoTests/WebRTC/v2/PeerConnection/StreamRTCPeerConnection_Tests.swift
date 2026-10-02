//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Dispatch
import ObjectiveC
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamRTCPeerConnection_Tests: XCTestCase, @unchecked Sendable {

    private var subject: StreamRTCPeerConnection!

    override func setUpWithError() throws {
        try super.setUpWithError()
        subject = try StreamRTCPeerConnection(
            .mock(),
            configuration: RTCConfiguration()
        )
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - close

    func test_setRemoteDescription_rollback_doesNotPublishAcceptedDescription()
        async throws {
        let factory = PeerConnectionFactory.mock()
        let offerSource = try factory.makePeerConnection(
            configuration: .init(),
            constraints: .defaultConstraints,
            delegate: nil
        )
        defer { offerSource.close() }
        _ = offerSource.addTransceiver(of: .video)
        let offer = try await offerSource.offer(for: .defaultConstraints)
        let subject = try StreamRTCPeerConnection(factory, configuration: .init())
        let acceptedDescriptions = Atomic(wrappedValue: 0)
        let cancellable = subject.subject.sink {
            if $0 is StreamRTCPeerConnection.HasRemoteDescription {
                acceptedDescriptions.mutate { $0 += 1 }
            }
        }
        defer { cancellable.cancel() }

        do {
            try await subject.setRemoteDescription(offer)
            XCTAssertEqual(acceptedDescriptions.wrappedValue, 1)
            try await subject.setRemoteDescription(.init(type: .rollback, sdp: ""))
            XCTAssertEqual(subject.signalingState, .stable)
            XCTAssertEqual(acceptedDescriptions.wrappedValue, 1)
        } catch {
            await subject.close()
            throw error
        }
        await subject.close()
    }

    func test_close_operationThrowsCancellationError() async {
        await subject.close()

        do {
            _ = try await subject.offer(for: .defaultConstraints)
            XCTFail("Expected the offer to fail after close.")
        } catch {
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
    }

    func test_statistics_invokesWebRTCOutsideCooperativePool() async throws {
        let selector = NSSelectorFromString("statisticsWithCompletionHandler:")
        let method = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, selector))
        let originalImplementation = method_getImplementation(method)
        let original = unsafeBitCast(
            originalImplementation,
            to: (@convention(c) (AnyObject, Selector, AnyObject) -> Void).self
        )
        let queues = Atomic(wrappedValue: [String]())
        let replacement: @convention(block) (RTCPeerConnection, AnyObject) -> Void = { connection, completion in
            queues.mutate { $0.append(String(cString: __dispatch_queue_get_label(nil))) }
            original(connection, selector, completion)
        }
        let replacementImplementation = imp_implementationWithBlock(replacement)
        method_setImplementation(method, replacementImplementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(replacementImplementation)
        }

        _ = try await subject.statistics()

        XCTAssertFalse(queues.wrappedValue.isEmpty)
        XCTAssertFalse(queues.wrappedValue.contains { $0.contains("cooperative") }, "\(queues.wrappedValue)")
        XCTAssertFalse(queues.wrappedValue.contains("com.apple.main-thread"))
    }

    func test_setRemoteDescription_completionAfterClose_doesNotPublishAcceptedDescription() async throws {
        try await assertRemoteDescriptionCompletion(closeBeforeDelivery: true)
    }

    func test_setRemoteDescription_completionBeforeClose_publishesAcceptedDescription() async throws {
        try await assertRemoteDescriptionCompletion(closeBeforeDelivery: false)
    }

    private func assertRemoteDescriptionCompletion(
        closeBeforeDelivery: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.mock()
        let offerSource = try factory.makePeerConnection(configuration: .init(), constraints: .defaultConstraints, delegate: nil)
        _ = offerSource.addTransceiver(of: .video)
        let offer = try await offerSource.offer(for: .defaultConstraints)
        offerSource.close()
        let subject = try StreamRTCPeerConnection(factory, configuration: .init())
        let nativeCompleted = expectation(description: "Successful native completion held")
        let nativeClosed = expectation(description: "Native close completed")
        let releaseCompletion = Atomic<(() -> Void)?>(wrappedValue: nil)
        let nativeSucceeded = Atomic(wrappedValue: false)
        let nativeConnection = Atomic<RTCPeerConnection?>(wrappedValue: nil)
        let acceptedDescriptions = Atomic(wrappedValue: 0)
        let cancellable = subject.subject.sink {
            if $0 is StreamRTCPeerConnection.HasRemoteDescription {
                acceptedDescriptions.mutate { $0 += 1 }
            }
        }
        let selector = NSSelectorFromString("setRemoteDescription:completionHandler:")
        let method = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, selector))
        let closeSelector = #selector(RTCPeerConnection.close)
        let closeMethod = try XCTUnwrap(class_getInstanceMethod(RTCPeerConnection.self, closeSelector))
        let originalIMP = method_getImplementation(method)
        let closeIMP = method_getImplementation(closeMethod)
        let original = unsafeBitCast(
            originalIMP,
            to: (@convention(c) (AnyObject, Selector, AnyObject, AnyObject) -> Void).self
        )
        let originalClose = unsafeBitCast(closeIMP, to: (@convention(c) (AnyObject, Selector) -> Void).self)
        let intercept: @convention(block) (RTCPeerConnection, AnyObject, AnyObject) -> Void = { connection, input, callback in
            nativeConnection.wrappedValue = connection
            let completion = unsafeBitCast(callback, to: (@convention(block) (NSError?) -> Void).self)
            let held: @convention(block) (NSError?) -> Void = { error in
                nativeSucceeded.wrappedValue = error == nil
                releaseCompletion.wrappedValue = { completion(error) }
                nativeCompleted.fulfill()
            }
            original(connection, selector, input, held as AnyObject)
        }
        let close: @convention(block) (RTCPeerConnection) -> Void = { connection in
            originalClose(connection, closeSelector)
            if connection === nativeConnection.wrappedValue { nativeClosed.fulfill() }
        }
        let interceptIMP = imp_implementationWithBlock(intercept)
        let closeInterceptIMP = imp_implementationWithBlock(close)
        method_setImplementation(method, interceptIMP)
        method_setImplementation(closeMethod, closeInterceptIMP)
        defer {
            releaseCompletion.wrappedValue?()
            method_setImplementation(method, originalIMP)
            method_setImplementation(closeMethod, closeIMP)
            imp_removeBlock(interceptIMP)
            imp_removeBlock(closeInterceptIMP)
            cancellable.cancel()
        }

        let operation = Task {
            do {
                try await subject.setRemoteDescription(offer)
                return false
            } catch {
                return error is CancellationError
            }
        }
        await fulfillment(of: [nativeCompleted], timeout: 5)
        XCTAssertTrue(nativeSucceeded.wrappedValue, "Held completion must be a real native success.", file: file, line: line)
        if closeBeforeDelivery {
            await subject.close()
            await fulfillment(of: [nativeClosed], timeout: 5)
        }
        let completion = try XCTUnwrap(releaseCompletion.wrappedValue)
        releaseCompletion.wrappedValue = nil
        completion()
        let wasCancelled = await operation.value

        XCTAssertEqual(wasCancelled, closeBeforeDelivery, file: file, line: line)
        XCTAssertEqual(acceptedDescriptions.wrappedValue, closeBeforeDelivery ? 0 : 1, file: file, line: line)
        if !closeBeforeDelivery {
            await subject.close()
            await fulfillment(of: [nativeClosed], timeout: 5)
        }
    }
}
