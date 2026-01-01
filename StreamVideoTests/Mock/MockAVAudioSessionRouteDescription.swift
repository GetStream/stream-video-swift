//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

final class MockAVAudioSessionRouteDescription: AVAudioSessionRouteDescription, @unchecked Sendable {

    var stubInputs: [AVAudioSessionPortDescription]
    var stubOutputs: [AVAudioSessionPortDescription]

    override var inputs: [AVAudioSessionPortDescription] { stubInputs }
    override var outputs: [AVAudioSessionPortDescription] { stubOutputs }

    init(
        inputs: [AVAudioSessionPortDescription] = [],
        outputs: [AVAudioSessionPortDescription] = []
    ) {
        stubInputs = inputs
        stubOutputs = outputs
        super.init()
    }
}
