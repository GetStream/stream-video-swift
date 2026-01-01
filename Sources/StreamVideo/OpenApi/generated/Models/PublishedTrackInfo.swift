//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PublishedTrackInfo: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var codecMimeType: String?
    public var durationSeconds: Int?
    public var trackType: String?

    public init(codecMimeType: String? = nil, durationSeconds: Int? = nil, trackType: String? = nil) {
        self.codecMimeType = codecMimeType
        self.durationSeconds = durationSeconds
        self.trackType = trackType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case codecMimeType = "codec_mime_type"
        case durationSeconds = "duration_seconds"
        case trackType = "track_type"
    }
    
    public static func == (lhs: PublishedTrackInfo, rhs: PublishedTrackInfo) -> Bool {
        lhs.codecMimeType == rhs.codecMimeType &&
            lhs.durationSeconds == rhs.durationSeconds &&
            lhs.trackType == rhs.trackType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(codecMimeType)
        hasher.combine(durationSeconds)
        hasher.combine(trackType)
    }
}
