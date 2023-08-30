//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import WebRTC
import MetalKit

class PiPRenderer: NSObject, RTCVideoRenderer {
    
    var feedFrames: ((CMSampleBuffer) -> ())?
    
    func setSize(_ size: CGSize) {}
    
    private var skip = false
    
    func renderFrame(_ frame: RTCVideoFrame?) {
        skip.toggle()
        if skip {
           return
        }
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            if let feedFrames {
                guard let frame = frame else {
                    return
                }

                if let pixelBuffer = frame.buffer as? RTCCVPixelBuffer {
                    guard let sampleBuffer = CMSampleBuffer.from(pixelBuffer.pixelBuffer) else {
                        log.warning("Failed to convert CVPixelBuffer to CMSampleBuffer")
                        return
                    }

                    feedFrames(sampleBuffer)
                } else if let i420buffer = frame.buffer as? RTCI420Buffer {
                    guard let buffer = convertI420BufferToPixelBuffer(i420buffer),
                            let sampleBuffer = CMSampleBuffer.from(buffer) else {
                        return
                    }
                    
                    feedFrames(sampleBuffer)
                }
            }
        }
    }
}
