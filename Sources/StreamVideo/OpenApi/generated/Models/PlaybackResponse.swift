//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// How the client should play the call when it is not given SFU credentials
public final class PlaybackResponse: Sendable, Decodable {
    
    public enum PlaybackResponseReason: String, Sendable, Codable, CaseIterable {
        case hint
        case percentage
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public enum PlaybackResponseType: String, Sendable, Codable, CaseIterable {
        case hls
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    /// URL of the HLS playlist to play
    public let playlistUrl: String
    /// Why this mode was chosen. One of: percentage, hint
    public let reason: PlaybackResponseReason
    /// Token to send as stats_token on HLS stats reports for this call session
    public let statsToken: String?
    /// Playback mode. One of: hls
    public let type: PlaybackResponseType

    public init(playlistUrl: String, reason: PlaybackResponseReason, statsToken: String? = nil, type: PlaybackResponseType) {
        self.playlistUrl = playlistUrl
        self.reason = reason
        self.statsToken = statsToken
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.playlistUrl = try container.decode(String.self, forKey: .playlistUrl)
        self.reason = try container.decode(PlaybackResponseReason.self, forKey: .reason)
        self.statsToken = try container.decodeIfPresent(String.self, forKey: .statsToken)
        self.type = try container.decode(PlaybackResponseType.self, forKey: .type)
    }
}

extension PlaybackResponse: Hashable {
    public static func == (lhs: PlaybackResponse, rhs: PlaybackResponse) -> Bool {
        lhs.playlistUrl == rhs.playlistUrl &&
            lhs.reason == rhs.reason &&
            lhs.statsToken == rhs.statsToken &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(playlistUrl)
        hasher.combine(reason)
        hasher.combine(statsToken)
        hasher.combine(type)
    }
}
