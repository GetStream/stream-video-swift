//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

@discardableResult
func XCTAssertThrowsErrorAsync(
    _ expression: () async throws -> Void,
    _ message: @autoclosure () -> String = "This method should fail",
    file: StaticString = #filePath,
    line: UInt = #line
) async -> Error? {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        return error
    }
    return nil
}
