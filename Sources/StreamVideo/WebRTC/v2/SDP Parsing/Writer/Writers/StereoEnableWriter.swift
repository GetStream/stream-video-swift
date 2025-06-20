//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

final class StereoEnableWriter: SDPLineWriter {

    enum State {
        case idle
        case foundMedia(line: String)
        case foundMid(mid: String)
        case foundOpus(mid: String, payload: String)
    }

    private var state: State = .idle
    private let data: [String: MidStereoInformation]

    /// Prefixes handled by this visitor: mid, rtpmap, and fmtp lines.
    var supportedPrefixes: Set<SupportedPrefix> {
        [.media, .mid, .rtmap, .fmtp]
    }

    init(_ data: [String: MidStereoInformation]) {
        self.data = data
    }

    func visit(line: String) -> String {
        switch (line, state) {
        case (_, .idle) where line.hasPrefix(SupportedPrefix.media.rawValue) && line.contains("audio") == true:
            state = .foundMedia(line: line)
            return line
        case (_, .foundMedia) where line.hasPrefix(SupportedPrefix.mid.rawValue):
            state = .foundMid(
                mid: line.replacingOccurrences(of: SupportedPrefix.mid.rawValue, with: "")
            )
            return line

        case let (_, .foundMid(mid)) where line.hasPrefix(SupportedPrefix.rtmap.rawValue):
            let parts = line.replacingOccurrences(of: SupportedPrefix.rtmap.rawValue, with: "")
                .split(separator: " ", maxSplits: 1)
            guard parts.endIndex == 2, parts[1].lowercased().contains("opus") else {
                state = .idle
                return line
            }
            state = .foundOpus(mid: mid, payload: String(parts[0]))
            return line

        case let (_, .foundOpus(mid, codecPayload)) where line.hasPrefix(SupportedPrefix.fmtp.rawValue):
            guard
                let entry = data[mid],
                entry.codecPayload == codecPayload,
                line.contains("stereo=1") == false
            else {
                state = .idle
                return line
            }

            state = .idle
            return line + ";stereo=1"

        default:
            return line
        }
    }
}
