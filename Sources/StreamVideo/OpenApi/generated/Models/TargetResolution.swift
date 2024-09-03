//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct TargetResolution: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var bitrate: Int? = nil
    public var height: Int
    public var width: Int

    public init(bitrate: Int? = nil, height: Int, width: Int) {
        self.bitrate = bitrate
        self.height = height
        self.width = width
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case height
        case width
    }
}
