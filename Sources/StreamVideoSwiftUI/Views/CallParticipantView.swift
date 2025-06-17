//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallParticipantView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
    private let imageSize: CGFloat = 48

    var viewFactory: Factory
    var participant: CallParticipant
    var menuActions: [CallParticipantMenuAction]

    init(
        viewFactory: Factory,
        participant: CallParticipant,
        menuActions: [CallParticipantMenuAction]
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.menuActions = menuActions
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                viewFactory.makeUserAvatar(
                    participant.user,
                    with: .init(size: imageSize) {
                        AnyView(
                            CircledTitleView(
                                title: participant.name.isEmpty
                                    ? participant.id
                                    : String(participant.name.uppercased().first!),
                                size: imageSize
                            )
                        )
                    }
                )
                .overlay(TopRightView { OnlineIndicatorView(indicatorSize: imageSize * 0.3) })

                Text(participant.name)
                    .font(fonts.bodyBold)
                Spacer()
                (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                    .foregroundColor(participant.hasAudio ? colors.text : colors.inactiveCallControl)

                (participant.hasVideo ? images.videoTurnOn : images.videoTurnOff)
                    .foregroundColor(participant.hasVideo ? colors.text : colors.inactiveCallControl)
            }
            .padding(.all, 4)

            Divider()
        }
        .contextMenu {
            ForEach(menuActions) { menuAction in
                Button {
                    menuAction.action(participant.userId)
                } label: {
                    HStack {
                        Image(systemName: menuAction.iconName)
                        Text(menuAction.title)
                        Spacer()
                    }
                }
            }
        }
        .debugViewRendering()
    }
}
