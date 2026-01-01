//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enumeration representing supported prefixes in SDP (Session Description Protocol) lines.
///
/// ## Overview
/// This enum provides a way to identify and handle specific prefixes in SDP lines,
/// which are commonly used in WebRTC communication to describe media and connection
/// details. It supports checking whether a given line starts with a supported prefix.
enum SupportedPrefix: String, Hashable, CaseIterable {

    /// Represents an unsupported prefix or no match.
    case unsupported

    /// Represents the `a=rtpmap:` prefix, commonly used in SDP to describe RTP payload formats.
    case rtmap = "a=rtpmap:"

    case media = "m="

    case mid = "a=mid:"

    case fmtp = "a=fmtp:"

    /// Determines if a line contains a supported prefix.
    ///
    /// - Parameter line: A `String` representing an SDP line.
    /// - Returns: A `SupportedPrefix` value indicating the matching prefix, or `.unsupported`
    ///   if no supported prefix is found.
    ///
    /// ## Example
    /// ```swift
    /// let line = "a=rtpmap:96 opus/48000/2"
    /// let prefix = SupportedPrefix.isPrefixSupported(for: line)
    /// print(prefix) // Output: .rtmap
    /// ```
    ///
    /// ## Notes
    /// This method checks all cases of the `SupportedPrefix` enum except `.unsupported`,
    /// and returns the first match if found.
    static func isPrefixSupported(for line: String) -> SupportedPrefix {
        guard
            let supportedPrefix = SupportedPrefix
            .allCases
            .first(where: { $0 != .unsupported && line.hasPrefix($0.rawValue) })
        else {
            return .unsupported
        }

        return supportedPrefix
    }
}
