//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct VideoResolution: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var height: Int
    public var width: Int

    public init(height: Int, width: Int) {
        self.height = height
        self.width = width
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case height
        case width
    }
}
