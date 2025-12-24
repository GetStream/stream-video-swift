//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioPCMBuffer {
    /// A debug-friendly summary of the buffer contents.
    override open var description: String {
        // Build a compact, readable representation for logs and debugging.
        var result = "{"
        // Pointer identity helps correlate buffers across logs.
        result += " address:\(Unmanaged.passUnretained(self).toOpaque())"
        // Include the full format to capture sample rate and layout details.
        result += ", format:\(self.format)"
        // Channel count is used to reason about mono vs stereo paths.
        result += ", channelCount:\(self.format.channelCount)"
        // Common format highlights float vs int and bit depth.
        result += ", commonFormat:\(self.format.commonFormat)"
        // Interleaving affects how samples are packed in memory.
        result += ", isInterleaved:\(self.format.isInterleaved)"
        // Float channel data is non-nil for float formats.
        result += ", floatChannelData:"
        result += "\(String(describing: self.floatChannelData))"
        // Int16 channel data is non-nil for 16-bit integer formats.
        result += ", int16ChannelData:"
        result += "\(String(describing: self.int16ChannelData))"
        result += " }"
        return result
    }
}

extension CMSampleBuffer {
    /// A debug-friendly summary of the sample buffer.
    public var description: String {
        // Build a compact, readable representation for logs and debugging.
        var result = "{"
        // Pointer identity helps correlate buffers across logs.
        result += " address:\(Unmanaged.passUnretained(self).toOpaque())"
        // Include the resolved audio format when available.
        result += ", format:\(String(describing: self.format))"
        // Channel count provides quick context for layout.
        result += ", channelCount:\(self.format?.mChannelsPerFrame ?? 0)"
        result += " }"
        return result
    }
}
