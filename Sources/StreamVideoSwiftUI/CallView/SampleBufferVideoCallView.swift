//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import AVKit

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }
}
