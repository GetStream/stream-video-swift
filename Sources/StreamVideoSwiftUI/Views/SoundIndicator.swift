//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct SoundIndicator: View {
            
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    let participant: CallParticipant
    
    public init(participant: CallParticipant) {
        self.participant = participant
    }
    
    public var body: some View {
        (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(participant.hasAudio ? .white : colors.inactiveCallControl)
            .accessibility(identifier: "participantMic")
            .streamAccessibility(value: participant.hasAudio ? "1" : "0")
            .debugViewRendering()
    }
}
