//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVAudioFormat {
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let _object = object as? AVAudioFormat else { return false }
        return self == _object
    }

    /// Compares formats by sample rate, channel count, and layout settings.
    public static func == (lhs: AVAudioFormat, rhs: AVAudioFormat) -> Bool {
        lhs.sampleRate == rhs.sampleRate &&
            lhs.channelCount == rhs.channelCount &&
            lhs.commonFormat == rhs.commonFormat &&
            lhs.isInterleaved == rhs.isInterleaved
    }
}
