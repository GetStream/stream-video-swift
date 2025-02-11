//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

public struct AudioSessionConfiguration: ReflectiveStringConvertible {
    var category: AVAudioSession.Category
    var mode: AVAudioSession.Mode
    var options: AVAudioSession.CategoryOptions
    var overrideOutputAudioPort: AVAudioSession.PortOverride?
}
