//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCCVPixelBuffer {

    public func bufferSizeForCroppingAndScaling(to size: CGSize) -> Int {
        Int(
            bufferSizeForCroppingAndScaling(
                toWidth: Int32(size.width),
                height: Int32(
                    size.height
                )
            )
        )
    }
}
