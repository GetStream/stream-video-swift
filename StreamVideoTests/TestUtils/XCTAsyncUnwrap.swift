//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {

    func XCTAsyncUnwrap<T>(
        _ expression: @autoclosure () async throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let expressionResult = try await expression()
        return try XCTUnwrap(expressionResult, message(), file: file, line: line)
    }
}
