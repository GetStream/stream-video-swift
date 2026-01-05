//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ThumbnailResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var imageUrl: String

    public init(imageUrl: String) {
        self.imageUrl = imageUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case imageUrl = "image_url"
    }
    
    public static func == (lhs: ThumbnailResponse, rhs: ThumbnailResponse) -> Bool {
        lhs.imageUrl == rhs.imageUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(imageUrl)
    }
}
