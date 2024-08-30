//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Images: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var fixedHeight: ImageData
    public var fixedHeightDownsampled: ImageData
    public var fixedHeightStill: ImageData
    public var fixedWidth: ImageData
    public var fixedWidthDownsampled: ImageData
    public var fixedWidthStill: ImageData
    public var original: ImageData

    public init(
        fixedHeight: ImageData,
        fixedHeightDownsampled: ImageData,
        fixedHeightStill: ImageData,
        fixedWidth: ImageData,
        fixedWidthDownsampled: ImageData,
        fixedWidthStill: ImageData,
        original: ImageData
    ) {
        self.fixedHeight = fixedHeight
        self.fixedHeightDownsampled = fixedHeightDownsampled
        self.fixedHeightStill = fixedHeightStill
        self.fixedWidth = fixedWidth
        self.fixedWidthDownsampled = fixedWidthDownsampled
        self.fixedWidthStill = fixedWidthStill
        self.original = original
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fixedHeight = "fixed_height"
        case fixedHeightDownsampled = "fixed_height_downsampled"
        case fixedHeightStill = "fixed_height_still"
        case fixedWidth = "fixed_width"
        case fixedWidthDownsampled = "fixed_width_downsampled"
        case fixedWidthStill = "fixed_width_still"
        case original
    }
}
