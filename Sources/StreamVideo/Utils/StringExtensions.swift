//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension String {
    
    var preferredRedCodec: String {
        let parts = self.components(separatedBy: "\r\n")
        var result = [String]()
        var redPrimary = false
        var opusIndex: Int?
        for (index, part) in parts.enumerated() {
            if part.contains(" opus/"), !redPrimary {
                opusIndex = index
            }
            if part.contains(" red/48000/2"), let opusIndex, !redPrimary {
                result.insert(part, at: opusIndex)
                redPrimary = true
            } else {
                result.append(part)
            }
        }
        return result.joined(separator: "\r\n")
    }
    
}
