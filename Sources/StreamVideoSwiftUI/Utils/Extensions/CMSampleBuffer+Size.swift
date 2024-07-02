//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreMedia
import Foundation

extension CMSampleBuffer {
    var size: CGSize? {
        guard let imageBuffer else {
            return nil
        }
        return CVImageBufferGetDisplaySize(imageBuffer)
    }
}
