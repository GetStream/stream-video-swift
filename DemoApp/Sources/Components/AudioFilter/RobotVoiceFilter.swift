//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

final class RobotVoiceFilter: AudioFilter {

    let pitchShift: Float

    init(pitchShift: Float) {
        self.pitchShift = pitchShift
    }

    // MARK: - AudioFilter

    var id: String { "robot-\(pitchShift)" }

    func applyEffect(to buffer: inout RTCAudioBuffer) {
        let frameSize = 256
        let hopSize = 128
        let scaleFactor = Float(frameSize) / Float(hopSize)

        let numFrames = (buffer.frames - frameSize) / hopSize

        for channel in 0..<buffer.channels {
            let channelBuffer = buffer.rawBuffer(forChannel: channel)

            for i in 0..<numFrames {
                let inputOffset = i * hopSize
                let outputOffset = Int(Float(i) * scaleFactor) * hopSize

                var outputFrame = [Float](repeating: 0.0, count: frameSize)

                // Apply pitch shift
                for j in 0..<frameSize {
                    let shiftedIndex = Int(Float(j) * pitchShift)
                    let originalIndex = inputOffset + j
                    if shiftedIndex >= 0 && shiftedIndex < frameSize && originalIndex >= 0 && originalIndex < buffer.frames {
                        outputFrame[shiftedIndex] = channelBuffer[originalIndex]
                    }
                }

                // Copy back to the input buffer
                for j in 0..<frameSize {
                    let outputIndex = outputOffset + j
                    if outputIndex >= 0 && outputIndex < buffer.frames {
                        channelBuffer[outputIndex] = outputFrame[j]
                    }
                }
            }
        }
    }
}
