//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSessionPortDescription {
    override public var description: String {
        "<Port type:\(portType.rawValue) name:\(portName)>"
    }
}
