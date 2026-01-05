//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A visitor for processing `a=rtpmap` lines.
final class RTPMapVisitor: SDPLineVisitor {
    private var codecMap: [String: Int] = [:]

    var supportedPrefixes: Set<SupportedPrefix> = [.rtmap]

    func visit(line: String) {
        // Parse the `a=rtpmap` line and extract codec information
        let components = line
            .replacingOccurrences(of: SupportedPrefix.rtmap.rawValue, with: "")
            .split(separator: " ")

        guard
            components.count == 2,
            let payloadType = Int(components[0])
        else {
            return
        }

        let codecName = components[1]
            .split(separator: "/")
            .first?
            .lowercased() ?? ""
        codecMap[codecName] = payloadType
    }
    
    /// Retrieves the payload type for a given codec name.
    /// - Parameter codec: The codec name to search for.
    /// - Returns: The payload type, or `nil` if not found.
    func payloadType(for codec: String) -> Int? {
        codecMap[codec.lowercased()]
    }
}
