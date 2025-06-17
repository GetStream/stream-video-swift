//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallingGroupView<Factory: ViewFactory>: View {

    let easeGently = Animation.easeOut(duration: 1).repeatForever(autoreverses: true)

    var viewFactory: Factory
    var participants: [Member]
    @State var isCalling: Bool

    init(
        viewFactory: Factory,
        participants: [Member],
        isCalling: Bool = false
    ) {
        self.viewFactory = viewFactory
        self.participants = participants
        self.isCalling = .init(isCalling)
    }

    var body: some View {
        VStack {
            if participants.count >= 3 {
                participantView(
                    for: participants[0],
                    scaleEffect: isCalling ? 1.2 : 0.8,
                    animation: easeGently.delay(0.2)
                )

                HStack(spacing: 16) {
                    participantView(
                        for: participants[1],
                        scaleEffect: isCalling ? 1.2 : 0.7,
                        animation: easeGently.delay(0.4)
                    )
                    
                    ZStack {
                        if participants.count == 3 {
                            IncomingCallParticipantView(
                                viewFactory: viewFactory,
                                participant: participants[2],
                                size: .standardAvatarSize
                            )
                        } else {
                            CircledTitleView(
                                title: "+\(participants.count - 2)",
                                size: .standardAvatarSize
                            )
                            .frame(width: .standardAvatarSize, height: .standardAvatarSize)
                        }
                    }
                    .background(
                        PulsatingCircle(
                            scaleEffect: isCalling ? 1.2 : 0.5,
                            opacity: 0.5,
                            isCalling: isCalling,
                            size: .standardAvatarSize,
                            animation: easeGently.delay(0.6)
                        )
                    )
                }
            } else {
                HStack(spacing: 16) {
                    ForEach(0..<participants.count, id: \.self) { index in
                        participantView(
                            for: participants[index],
                            scaleEffect: isCalling ? 1.2 : 0.5,
                            animation: easeGently.delay(0.2 + Double(index) * 0.2)
                        )
                    }
                }
            }
        }
        .onAppear {
            isCalling.toggle()
        }
    }

    @ViewBuilder
    private func participantView(
        for participant: Member,
        scaleEffect: CGFloat,
        animation: Animation
    ) -> some View {
        IncomingCallParticipantView(
            viewFactory: viewFactory,
            participant: participant,
            size: .standardAvatarSize
        )
        .background(
            PulsatingCircle(
                scaleEffect: scaleEffect,
                opacity: 0.5,
                isCalling: isCalling,
                size: .standardAvatarSize,
                animation: animation
            )
        )
    }
}
