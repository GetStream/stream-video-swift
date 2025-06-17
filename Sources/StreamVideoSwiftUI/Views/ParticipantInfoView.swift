//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ParticipantInfoView: View {
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    
    var participant: CallParticipant
    var isPinned: Bool
    var maxHeight: CGFloat

    public init(
        participant: CallParticipant,
        isPinned: Bool,
        maxHeight: Float = 14
    ) {
        self.participant = participant
        self.isPinned = isPinned
        self.maxHeight = CGFloat(maxHeight)
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: maxHeight)
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            }
            Text(participant.name.isEmpty ? participant.id : participant.name)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(fonts.caption1)
                .minimumScaleFactor(0.7)
                .accessibility(identifier: "participantName")
                        
            SoundIndicator(participant: participant)
                .frame(maxHeight: maxHeight)
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
        .frame(height: 28)
        .cornerRadius(
            8,
            corners: [.topRight],
            backgroundColor: colors.participantInfoBackgroundColor
        )
    }
}
