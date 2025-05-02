//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class Publisher_TaskCompactMapTests: XCTestCase, @unchecked Sendable {

    private var disposableBag: DisposableBag! = .init()

    override func tearDown() {
        disposableBag.removeAll()
        disposableBag = nil
        super.tearDown()
    }

    // MARK: - compactMapTask

    func test_compactMapTask_withSuccessfulTransformation() {
        let expectation = XCTestExpectation(description: "Publisher transforms value successfully")
        let publisher = Just("Test")
            .setFailureType(to: Error.self)

        let transformedPublisher = publisher.compactMapTask { value in
            XCTAssertEqual(value, "Test")
            return value.uppercased()
        }

        transformedPublisher.sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                XCTAssertEqual(value, "TEST")
            }
        ).store(in: disposableBag)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_compactMapTask_withNilTransformation() {
        let expectation = XCTestExpectation(description: "Publisher transforms value to nil")
        let publisher = Just("Test")
            .setFailureType(to: Error.self)

        publisher
            .compactMapTask { (value: String) -> String? in
                XCTAssertEqual(value, "Test")
                return nil
            }.sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value")
                }
            ).store(in: disposableBag)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_compactMapTask_withFailure() {
        enum TestError: Error {
            case test
        }

        let expectation = XCTestExpectation(description: "Publisher completes with failure")
        let publisher = Fail<String, TestError>(error: .test)

        let transformedPublisher = publisher.compactMapTask { value in
            XCTFail("Should not receive value")
            return value
        }

        transformedPublisher.sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTAssertEqual(error, TestError.test)
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in
                XCTFail("Should not receive value")
            }
        ).store(in: disposableBag)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_compactMapTask_withDisposableBag() {
        let expectation = XCTestExpectation(description: "Task is stored in disposable bag")
        let publisher = Just("Test")
            .setFailureType(to: Error.self)

        let transformedPublisher = publisher.compactMapTask(
            storeIn: disposableBag,
            identifier: "testTask"
        ) { value in
            XCTAssertEqual(value, "Test")
            return value.uppercased()
        }

        transformedPublisher.sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                XCTAssertEqual(value, "TEST")
            }
        ).store(in: disposableBag)

        wait(for: [expectation], timeout: 1.0)
    }
}
