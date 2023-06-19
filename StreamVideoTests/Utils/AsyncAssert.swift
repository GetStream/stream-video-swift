//
//  AsyncAssert.swift
//  StreamVideoTests
//
//  Created by tommaso barbugli on 19/06/2023.
//

import Foundation
import XCTest

func XCTAssertThrowsErrorAsync(
    _ expression: () async throws -> Void,
    _ message: @autoclosure () -> String = "This method should fail",
    file: StaticString = #filePath,
    line: UInt = #line
) async -> Error? {
    do {
        let _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        return error
    }
    return nil
}
