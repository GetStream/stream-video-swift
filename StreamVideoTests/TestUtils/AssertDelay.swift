//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

@MainActor
func XCTAssertWithDelay(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String = "",
    nanoseconds: UInt64 = 500_000_000,
    file: StaticString = #file,
    line: UInt = #line
) async throws {
    try await Task.sleep(nanoseconds: nanoseconds)
    XCTAssert(try expression(), message(), file: file, line: line)
}
