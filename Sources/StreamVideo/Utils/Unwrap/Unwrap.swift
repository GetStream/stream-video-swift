//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A function to safely unwrap an optional value. If the value is `nil`, it
/// throws a `ClientError` with a custom error message, file, and line number
/// for better error tracing.
///
/// - Parameters:
///   - value: The optional value to be unwrapped. If the value is `nil`, an
///            error will be thrown.
///   - errorMessage: A custom error message that will be used in the thrown
///                   `ClientError` if the value is `nil`. The default is
///                   `"Unavailable value"`.
///   - file: The file from which the function was called, using the `#fileID`
///           directive to capture the source location. Default is the
///           calling file.
///   - line: The line number from which the function was called, using the
///           `#line` directive to capture the source line number. Default is
///           the calling line.
///
/// - Throws: A `ClientError` if the value is `nil`, with the provided error
///           message, file, and line number.
///
/// - Returns: The unwrapped value of the optional if it's not `nil`.
///
/// - Example:
/// ```swift
/// let name: String? = nil
/// let unwrappedName = try unwrap(name, errorMessage: "Name is missing")
/// // This will throw a ClientError.
/// ```
func unwrap<T>(
    _ value: T?,
    errorMessage: String = "Unavailable value",
    file: StaticString = #fileID,
    line: UInt = #line
) throws -> T {
    guard let value else {
        throw ClientError(errorMessage, file, line)
    }
    return value
}
