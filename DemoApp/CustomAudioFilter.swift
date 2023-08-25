//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
import Accelerate

protocol AudioFilter {
    
    func applyEffect(to audioBuffer: inout RTCAudioBuffer)
    
}

class CustomVoiceProcessor: NSObject, RTCAudioCustomProcessingDelegate {
        
    private var audioFilter: AudioFilter?
    
    func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {}
    
    func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        var audioBuffer = audioBuffer
        audioFilter?.applyEffect(to: &audioBuffer)
    }
    
    func audioProcessingRelease() {}
    
    func setAudioFilter(_ audioFilter: AudioFilter?) {
        self.audioFilter = audioFilter
    }
}


class RobotVoiceFilter: AudioFilter {
    
    let pitchShift: Float
    
    init(pitchShift: Float) {
        self.pitchShift = pitchShift
    }
    
    func applyEffect(to audioBuffer: inout RTCAudioBuffer) {
        let frameSize = 256
        let hopSize = 128
        let scaleFactor = Float(frameSize) / Float(hopSize)
        
        let numFrames = (audioBuffer.frames - frameSize) / hopSize
        
        for channel in 0..<audioBuffer.channels {
            let channelBuffer = audioBuffer.rawBuffer(forChannel: channel)
            
            for i in 0..<numFrames {
                let inputOffset = i * hopSize
                let outputOffset = Int(Float(i) * scaleFactor) * hopSize
                
                var outputFrame = [Float](repeating: 0.0, count: frameSize)
                
                // Apply pitch shift
                for j in 0..<frameSize {
                    let shiftedIndex = Int(Float(j) * pitchShift)
                    let originalIndex = inputOffset + j
                    if shiftedIndex >= 0 && shiftedIndex < frameSize && originalIndex >= 0 && originalIndex < audioBuffer.frames {
                        outputFrame[shiftedIndex] = channelBuffer[originalIndex]
                    }
                }
                
                // Copy back to the input buffer
                for j in 0..<frameSize {
                    let outputIndex = outputOffset + j
                    if outputIndex >= 0 && outputIndex < audioBuffer.frames {
                        channelBuffer[outputIndex] = outputFrame[j]
                    }
                }
            }
        }
    }
}
