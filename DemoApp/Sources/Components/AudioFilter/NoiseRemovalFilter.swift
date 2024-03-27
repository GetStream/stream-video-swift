//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class NoiseRemovalFilter: AudioFilter {
    
    let noiseRemoval = NoiseRemovalHelper()

    func applyEffect(to audioBuffer: inout RTCAudioBuffer, sampleRate: Int) {
        for channel in 0..<audioBuffer.channels {
            let channelBuffer = audioBuffer.rawBuffer(forChannel: channel)
            let totalFrames = Int(audioBuffer.frames)
            
            let result = noiseRemoval.denoise(
                withBuffer: channelBuffer,
                frameSize: Int32(totalFrames)
            )
            
            for i in 0..<totalFrames {
                if let value = result?[i] {
                    channelBuffer[i] = value
                }
            }
        }
    }
    
    deinit {
        noiseRemoval.destroy()
    }
}

func convertPointerToArray(pointer: UnsafeMutablePointer<Float>, count: Int) -> [Float] {
    let bufferPointer = UnsafeBufferPointer(start: pointer, count: count)
    return Array(bufferPointer)
}
