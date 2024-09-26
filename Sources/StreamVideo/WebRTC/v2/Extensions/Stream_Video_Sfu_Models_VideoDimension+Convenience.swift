//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Models_VideoDimension {
    init(_ size: CGSize) {
        height = UInt32(size.height)
        width = UInt32(size.width)
    }
}
