//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PublishedTrackInfo: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
