//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class ConsumableBucket_Tests: XCTestCase, @unchecked Sendable {

    func test_append_and_consume_returnsAppendedElements() {
        let subject = ConsumableBucket<Int>()
        subject.append(1)
        subject.append(2)

        let result = subject.consume()
        XCTAssertEqual(result, [1, 2])
    }

    func test_consume_flush_clearsBuffer() {
        let subject = ConsumableBucket<String>()
        subject.append("a")
        subject.append("b")

        let flushed = subject.consume(flush: true)
        XCTAssertEqual(flushed, ["a", "b"])

        let afterFlush = subject.consume()
        XCTAssertEqual(afterFlush, [])
    }

    func test_insert_addsItemsAtCorrectIndex() {
        let subject = ConsumableBucket<Int>()
        subject.append(1)
        subject.append(4)
        subject.insert([2, 3], at: 1)

        let result = subject.consume()
        XCTAssertEqual(result, [1, 2, 3, 4])
    }

    func test_publisherBasedBucket_receivesPublishedItems() {
        let subjectPublisher = PassthroughSubject<Int, Never>()
        let subject = ConsumableBucket(subjectPublisher.eraseToAnyPublisher())

        subjectPublisher.send(10)
        subjectPublisher.send(20)

        let result = subject.consume()
        XCTAssertEqual(result, [10, 20])
    }

    func test_transformingPublisher_appliesTransformationCorrectly() {
        let publisher = PassthroughSubject<String, Never>()
        let subject = ConsumableBucket(
            publisher.eraseToAnyPublisher(),
            transformer: StringLengthTransformer()
        )

        publisher.send("abc")
        publisher.send("hello")

        let result = subject.consume()
        XCTAssertEqual(result, [3, 5])
    }

    func test_transformingPublisher_removesDuplicatesWhenEnabled() {
        let publisher = PassthroughSubject<String, Never>()
        let subject = ConsumableBucket(
            publisher.eraseToAnyPublisher(),
            transformer: StringLengthTransformer(),
            removeDuplicates: true
        )

        publisher.send("abc")
        publisher.send("abc")
        publisher.send("hello")

        let result = subject.consume()
        XCTAssertEqual(result, [3, 5])
    }

    func test_threadSafety_underConcurrentAccess_withTaskGroup() async {
        let subject = ConsumableBucket<Int>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<1000 {
                group.addTask {
                    subject.append(i)
                }
            }
        }

        let result = subject.consume()
        XCTAssertEqual(result.count, 1000)
        XCTAssertEqual(Set(result).count, 1000)
    }

    func test_threadSafety_whenConsumingWhileAppending_withTaskGroup() async {
        let subject = ConsumableBucket<Int>()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<500 {
                group.addTask {
                    subject.append(i)
                }
                group.addTask {
                    _ = subject.consume()
                }
            }
        }

        let final = subject.consume()
        XCTAssertLessThanOrEqual(final.count, 500)
    }

    // MARK: - Helpers

    private struct StringLengthTransformer: ConsumableBucketItemTransformer {
        func transform(_ input: String) -> Int? {
            input.count
        }
    }
}
