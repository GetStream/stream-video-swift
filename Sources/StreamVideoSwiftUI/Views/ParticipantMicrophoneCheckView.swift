//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct ParticipantMicrophoneCheckView: View {

    var audioLevels: [Float]
    var microphoneOn: Bool
    var isSilent: Bool
    var isPinned: Bool

    var body: some View {
        MicrophoneCheckView(
            audioLevels: audioLevels,
            microphoneOn: microphoneOn,
            isSilent: isSilent,
            isPinned: isPinned
        )
        .accessibility(identifier: "microphoneCheckView")
    }
}
