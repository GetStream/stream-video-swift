//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class AnyEncodable_Tests: XCTestCase, @unchecked Sendable {

    func test_encode_encodableValue_encodesCorrectly() throws {
        struct Sample: Codable, Equatable {
            let value: Int
        }

        let original = Sample(value: 42)
        let subject = AnyEncodable(original)

        let encoder = JSONEncoder()
        let data = try encoder.encode(subject)
        let decoded = try JSONDecoder().decode(Sample.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func test_equality_equatableValues_areEqualWhenEqual() {
        struct Sample: Encodable, Equatable {
            let value: Int
        }

        let a = AnyEncodable(Sample(value: 1))
        let b = AnyEncodable(Sample(value: 1))

        XCTAssertEqual(a, b)
    }

    func test_equality_equatableValues_areNotEqualWhenDifferent() {
        struct Sample: Encodable, Equatable {
            let value: Int
        }

        let a = AnyEncodable(Sample(value: 1))
        let b = AnyEncodable(Sample(value: 2))

        XCTAssertNotEqual(a, b)
    }

    func test_equality_nonEquatableValues_areNeverEqual() {
        struct Sample: Encodable {
            let value: Int
        }

        let a = AnyEncodable(Sample(value: 1))
        let b = AnyEncodable(Sample(value: 1))

        XCTAssertNotEqual(a, b)
    }

    func test_identity_existingAnyEncodable_isPreserved() {
        struct Sample: Encodable, Equatable {
            let value: Int
        }

        let inner = AnyEncodable(Sample(value: 1))
        let subject = AnyEncodable(inner)

        XCTAssertEqual(inner, subject)
    }
}
