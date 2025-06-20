//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A visitor that enables stereo in the answer SDP based on stereo being offered.
final class StereoEnableVisitor: SDPLineVisitor {

    enum State {
        case idle
        case foundMedia(line: String)
        case foundMid(mid: String)
        case foundOpus(mid: String, payload: String)
    }

    private var state: State = .idle
    private(set) var found: [String: MidStereoInformation] = [:]

    /// Prefixes handled by this visitor: mid, rtpmap, and fmtp lines.
    var supportedPrefixes: Set<SupportedPrefix> {
        [.media, .mid, .rtmap, .fmtp]
    }

    init() {}

    func visit(line: String) {
        switch (line, state) {
        case (_, .idle) where line.hasPrefix(SupportedPrefix.media.rawValue) && line.contains("audio") == true:
            state = .foundMedia(line: line)
        case (_, .foundMedia) where line.hasPrefix(SupportedPrefix.mid.rawValue):
            state = .foundMid(
                mid: line.replacingOccurrences(of: SupportedPrefix.mid.rawValue, with: "")
            )

        case let (_, .foundMid(mid)) where line.hasPrefix(SupportedPrefix.rtmap.rawValue):
            let parts = line.replacingOccurrences(of: SupportedPrefix.rtmap.rawValue, with: "")
                .split(separator: " ", maxSplits: 1)
            guard parts.endIndex == 2, parts[1].lowercased().contains("opus") else {
                state = .idle
                return
            }
            state = .foundOpus(mid: mid, payload: String(parts[0]))

        case let (_, .foundOpus(mid, codecPayload)) where line.hasPrefix(SupportedPrefix.fmtp.rawValue):
            let parts = line
                .replacingOccurrences(of: SupportedPrefix.fmtp.rawValue, with: "")
                .split(separator: " ", maxSplits: 1)

            guard parts.endIndex == 2 else {
                state = .idle
                return
            }

            let payload = String(parts[0])
            let config = String(parts[1])

            guard
                payload == codecPayload,
                config.contains("stereo=1")
            else {
                state = .idle
                return
            }

            found[mid] = .init(
                mid: mid,
                codecPayload: codecPayload,
                isStereoEnabled: true
            )
            state = .idle

        default:
            break
        }
    }
}
