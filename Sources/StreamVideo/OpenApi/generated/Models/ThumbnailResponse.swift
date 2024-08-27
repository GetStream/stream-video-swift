//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ThumbnailResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var imageUrl: String

    public init(imageUrl: String) {
        self.imageUrl = imageUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case imageUrl = "image_url"
    }
}
