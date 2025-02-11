//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

public struct AudioSessionConfiguration: ReflectiveStringConvertible, Equatable {
    var category: AVAudioSession.Category
    var mode: AVAudioSession.Mode
    var options: AVAudioSession.CategoryOptions
    var overrideOutputAudioPort: AVAudioSession.PortOverride?
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.category == rhs.category &&
            lhs.mode == rhs.mode &&
            lhs.options.rawValue == rhs.options.rawValue &&
            lhs.overrideOutputAudioPort?.rawValue == rhs.overrideOutputAudioPort?.rawValue
    }
}
