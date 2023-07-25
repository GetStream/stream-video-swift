//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class BroadcastUtils {
    
    static func adjust(width: Int32, height: Int32, size: Int32) -> (width: Int32, height: Int32) {
        let dimensions = aspectFit(width: width, height: height, size: size)
        return toSafeDimensions(width: dimensions.width, height: dimensions.height)
    }
    
    static func toSafeDimensions(width: Int32, height: Int32) -> (width: Int32, height: Int32) {
        (
            width: max(16, width.roundUp(toMultipleOf: 2)),
            height: max(16, height.roundUp(toMultipleOf: 2))
        )
    }
    
    static func aspectFit(width: Int32, height: Int32, size: Int32) -> (width: Int32, height: Int32) {
        let isWider = width >= height
        let ratio = isWider ? Double(height) / Double(width) : Double(width) / Double(height)
        return (
            width: isWider ? size : Int32(ratio * Double(size)),
            height: isWider ? Int32(ratio * Double(size)) : size
        )
    }
}
