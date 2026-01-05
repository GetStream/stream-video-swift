//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioSessionRouteDescription {
    static func dummy(
        input: AVAudioSession.Port = .builtInMic,
        output: AVAudioSession.Port = .builtInReceiver
    ) -> AVAudioSessionRouteDescription {
        MockAVAudioSessionRouteDescription(
            inputs: [MockAVAudioSessionPortDescription(portType: input)],
            outputs: [MockAVAudioSessionPortDescription(portType: output)]
        )
    }
}
