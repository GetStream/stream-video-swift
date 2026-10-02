//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
}
