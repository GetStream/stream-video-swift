//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

struct CallingGroupView<Factory: ViewFactory>: View {

    @Injected(\.layout) private var layout

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
        VStack(spacing: layout.spacingXs) {
            if participants.count >= 3 {
                participantView(
                    for: participants[0],
                    scaleEffect: isCalling ? 1.2 : 0.8,
                    animation: easeGently.delay(0.2)
                )

                HStack(spacing: layout.spacingMd) {
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
                HStack(spacing: layout.spacingMd) {
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

struct IncomingCallParticipantView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var participant: Member
    var size: CGFloat

    init(
        viewFactory: Factory,
        participant: Member,
        size: CGFloat = .expandedAvatarSize
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.size = size
    }

    var body: some View {
        viewFactory.makeUserAvatar(
            participant.user,
            with: .init(size: size) {
                AnyView(CircledTitleView(title: title, size: size))
            }
        )
        .frame(width: size, height: size)
        .modifier(ShadowModifier())
        .animation(nil)
    }

    private var title: String {
        let name = participant.user.name.isEmpty ? "Unknown" : participant.user.name
        let title = String(name.uppercased().first!)
        return title
    }
}

struct CircledTitleView: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
    var title: String
    var size: CGFloat = .expandedAvatarSize
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(
                    Color(colors.accentPrimary)
                )
            Text(title)
                .foregroundColor(
                    Color(colors.textOnAccent)
                )
                .font(fonts.title)
                .minimumScaleFactor(0.4)
                .padding(layout.spacingMd)
        }
        .frame(maxWidth: size, maxHeight: size)
        .modifier(ShadowModifier())
    }
}
