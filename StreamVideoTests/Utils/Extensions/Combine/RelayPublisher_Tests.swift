//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class RelayPublisher_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Replay

    func test_valueSentBeforeSubscription_isReplayed() async throws {
        let source = PassthroughSubject<Int, Error>()
        let relay = source.relay()

        source.send(42)

        let result = try await relay.nextValue(timeout: 2)
        XCTAssertEqual(result, 42)
    }

    func test_valueSentAfterSubscription_isDelivered() async throws {
        let source = PassthroughSubject<Int, Error>()
        let relay = source.relay()

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            source.send(7)
        }

        let result = try await relay.nextValue(timeout: 2)
        XCTAssertEqual(result, 7)
    }

    func test_onlyLatestValue_isReplayed() async throws {
        let source = PassthroughSubject<Int, Error>()
        let relay = source.relay()

        source.send(1)
        source.send(2)
        source.send(3)

        let result = try await relay.nextValue(timeout: 2)
        XCTAssertEqual(result, 3)
    }

    func test_optionalNilValueSentBeforeSubscription_isReplayed() async throws {
        let source = PassthroughSubject<Int?, Error>()
        let relay = source.relay()

        source.send(nil)

        let result = try await relay.nextValue(timeout: 2)
        XCTAssertNil(result)
    }

    // MARK: - Completion

    func test_upstreamCompletion_isForwarded() async {
        let source = PassthroughSubject<Int, Error>()
        let relay = source.relay()

        let expectation = XCTestExpectation(
            description: "Completion received"
        )

        let cancellable = relay.sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { _ in }
        )

        source.send(completion: .finished)

        await fulfillment(of: [expectation], timeout: 1)
        cancellable.cancel()
    }

    func test_upstreamError_isForwarded() async {
        let source = PassthroughSubject<Int, Error>()
        let relay = source.relay()

        let expectation = XCTestExpectation(
            description: "Error received"
        )
        let expectedError = ClientError("boom")

        var receivedError: Error?
        let cancellable = relay.sink(
            receiveCompletion: {
                if case let .failure(error) = $0 {
                    receivedError = error
                }
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )

        source.send(completion: .failure(expectedError))

        await fulfillment(of: [expectation], timeout: 1)
        XCTAssertEqual(
            (receivedError as? ClientError)?.localizedDescription,
            expectedError.localizedDescription
        )
        cancellable.cancel()
    }

    // MARK: - No value

    func test_noValueSent_timesOut() async {
        let source = PassthroughSubject<Int, Error>()
        let relay = source.relay()

        do {
            _ = try await relay.nextValue(timeout: 0.3)
            XCTFail("Expected timeout.")
        } catch {
            XCTAssertTrue(error is TimeOutError)
        }
    }

    // MARK: - Contrast with bare PassthroughSubject

    func test_passthroughSubject_valueSentBeforeSubscription_isLost() async {
        let source = PassthroughSubject<Int, Error>()

        source.send(42)

        do {
            _ = try await source.nextValue(timeout: 0.3)
            XCTFail("Expected timeout because the value was lost.")
        } catch {
            XCTAssertTrue(error is TimeOutError)
        }
    }
}
