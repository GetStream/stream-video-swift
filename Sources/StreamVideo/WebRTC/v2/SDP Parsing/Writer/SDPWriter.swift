//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The main SDP parser that uses visitors to process lines.
final class SDPWriter {
    private var writers: [SDPLineWriter] = []

    /// Registers a visitor for a specific SDP line prefix.
    /// - Parameters:
    ///   - prefix: The line prefix to handle (e.g., "a=rtpmap").
    ///   - visitor: The visitor that processes lines with the specified prefix.
    func registerWriter(_ writer: SDPLineWriter) {
        writers.append(writer)
    }
    
    func write(sdp: String) async -> String {
        let lines = sdp.split(separator: "\r\n")
        var updatedLines = [String]()
        for line in lines {
            let line = String(line)
            let supportedPrefix = SupportedPrefix.isPrefixSupported(for: line)
            guard
                supportedPrefix != .unsupported
            else {
                updatedLines.append(line)
                continue
            }

            let updatedLine = writers.reduce(line) { partialResult, writer in
                writer.visit(line: partialResult)
            }

            updatedLines.append(updatedLine)
        }
        updatedLines.append("\n")

        return updatedLines.joined(separator: "\r\n")
    }
}
