//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

@MainActor
func XCTAssertWithDelay(
    _ expression: @autoclosure () throws -> Bool,
    nanoseconds: UInt64 = 500_000_000
) async throws {
    try await Task.sleep(nanoseconds: nanoseconds)
    XCTAssert(try expression())
}
