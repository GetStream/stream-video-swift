//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    private enum Constants {
        static let fmtpDelimiter: Character = ";"
        static let keyValueSeparator: Character = "="
        static let stereoParameters: [(key: String, value: String)] = [
            ("stereo", "1"),
            ("sprop-stereo", "1")
        ]
    }

    private var state: State = .idle
    private(set) var found: [String: MidStereoInformation] = [:]
    private(set) var fmtpLineReplacements: [String: String] = [:]

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
            let originalLine = line
            let parts = line
                .replacingOccurrences(of: SupportedPrefix.fmtp.rawValue, with: "")
                .split(separator: " ", maxSplits: 1)

            guard parts.endIndex == 2 else {
                state = .idle
                return
            }

            let payload = String(parts[0])
            let config = String(parts[1])

            guard payload == codecPayload else {
                state = .idle
                return
            }

            let (updatedConfig, didMutate) = ensureStereoConfiguration(in: config)
            if didMutate {
                let updatedLine = "\(SupportedPrefix.fmtp.rawValue)\(payload) \(updatedConfig)"
                fmtpLineReplacements[originalLine] = updatedLine
            } else {
                fmtpLineReplacements.removeValue(forKey: originalLine)
            }

            found[mid] = .init(
                mid: mid,
                codecPayload: codecPayload,
                isStereoEnabled: updatedConfig.contains("stereo=1")
            )
            state = .idle

        default:
            break
        }
    }

    /// Applies the computed stereo updates to the provided SDP, returning a new SDP string.
    /// - Parameter sdp: The original SDP string.
    /// - Returns: The SDP string with stereo parameters enforced where required.
    func applyStereoUpdates(to sdp: String) -> String {
        guard fmtpLineReplacements.isEmpty == false else { return sdp }

        let delimiter = "\r\n"
        var lines = sdp.components(separatedBy: delimiter)

        for index in lines.indices {
            let line = lines[index]
            if let replacement = fmtpLineReplacements[line] {
                lines[index] = replacement
            }
        }

        return lines.joined(separator: delimiter)
    }

    /// Resets the internal state allowing the visitor to be reused.
    func reset() {
        state = .idle
        found.removeAll()
        fmtpLineReplacements.removeAll()
    }

    private func ensureStereoConfiguration(in config: String) -> (String, Bool) {
        let components = config
            .split(separator: Constants.fmtpDelimiter)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var order: [String] = []
        var values: [String: String] = [:]

        for component in components {
            let keyValue = component.split(separator: Constants.keyValueSeparator, maxSplits: 1)
            let key = keyValue[0].trimmingCharacters(in: .whitespaces)
            let value = keyValue.count > 1
                ? keyValue[1].trimmingCharacters(in: .whitespaces)
                : ""

            if values[key] == nil {
                order.append(key)
            }
            values[key] = value
        }

        var didMutate = false

        for (key, value) in Constants.stereoParameters {
            if let existing = values[key] {
                if existing != value {
                    values[key] = value
                    didMutate = true
                }
            } else {
                values[key] = value
                order.append(key)
                didMutate = true
            }
        }

        let updatedConfig = order.map { key -> String in
            guard let value = values[key], value.isEmpty == false else {
                return key
            }
            return "\(key)=\(value)"
        }.joined(separator: String(Constants.fmtpDelimiter))

        return (updatedConfig, didMutate)
    }
}
