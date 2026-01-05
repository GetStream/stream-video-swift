//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The main SDP parser that uses visitors to process lines.
final class SDPParser {
    private var visitors: [SDPLineVisitor] = []

    /// Registers a visitor for a specific SDP line prefix.
    /// - Parameters:
    ///   - prefix: The line prefix to handle (e.g., "a=rtpmap").
    ///   - visitor: The visitor that processes lines with the specified prefix.
    func registerVisitor(_ visitor: SDPLineVisitor) {
        visitors.append(visitor)
    }

    /// Parses the provided SDP string asynchronously.
    /// - Parameter sdp: The SDP string to parse.
    func parse(sdp: String) async {
        let lines = sdp.split(separator: "\r\n")
        for line in lines {
            let line = String(line)
            let supportedPrefix = SupportedPrefix.isPrefixSupported(for: line)
            guard
                supportedPrefix != .unsupported
            else {
                continue
            }

            visitors.forEach {
                guard
                    $0.supportedPrefixes.contains(supportedPrefix)
                else {
                    return
                }
                $0.visit(line: line)
            }
        }
    }
}
