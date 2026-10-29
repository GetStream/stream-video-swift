//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ThumbnailResponse: @unchecked Sendable, Decodable {
    public var imageUrl: String

    public init(imageUrl: String) {
        self.imageUrl = imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.imageUrl = try container.decode(String.self, forKey: .imageUrl)
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
