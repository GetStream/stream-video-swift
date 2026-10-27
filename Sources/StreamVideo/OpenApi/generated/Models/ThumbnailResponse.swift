//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ThumbnailResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var imageUrl: String

    public init(imageUrl: String) {
        self.imageUrl = imageUrl
    }

    public enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}

extension ThumbnailResponse: Hashable {
    public static func == (lhs: ThumbnailResponse, rhs: ThumbnailResponse) -> Bool {
        lhs.imageUrl == rhs.imageUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(imageUrl)
    }
}
