//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoCallParticipantSpeakingModifier: ViewModifier {

    @Injected(\.colors) var colors

    public var participant: CallParticipant
    public var participantCount: Int

    public init(
        participant: CallParticipant,
        participantCount: Int
    ) {
        self.participant = participant
        self.participantCount = participantCount
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if participant.isSpeaking, participantCount > 1 {
                        RoundedRectangle(cornerRadius: 16).strokeBorder(
                            colors.participantSpeakingHighlightColor,
                            lineWidth: 2
                        )
                    }
                }
            )
    }
}
