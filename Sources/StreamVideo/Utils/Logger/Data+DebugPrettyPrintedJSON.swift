//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Relocated here from the deleted `Logger.swift` during the StreamCore logger
// migration. Kept as a video-internal extension (StreamCore also declares a
// public `Data.debugPrettyPrintedJSON`): keeping ours out of any
// StreamCore-importing file avoids an ambiguous member at the call sites that
// use it without importing StreamCore.
extension Data {
    /// Converts the data into a pretty-printed JSON string. Use only for debug
    /// purposes since this operation can be expensive.
    var debugPrettyPrintedJSON: String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let prettyPrintedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted]
            )
            return String(data: prettyPrintedData, encoding: .utf8)
                ?? "Error: Data to String decoding failed."
        } catch {
            return "<not available string representation>"
        }
    }
}
