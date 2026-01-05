//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        struct CustomParticipantModifier: ViewModifier {

            var participant: CallParticipant
            var call: Call?
            var availableFrame: CGRect
            var ratio: CGFloat
            var showAllInfo: Bool

            public init(
                participant: CallParticipant,
                call: Call?,
                availableFrame: CGRect,
                ratio: CGFloat,
                showAllInfo: Bool
            ) {
                self.participant = participant
                self.call = call
                self.availableFrame = availableFrame
                self.ratio = ratio
                self.showAllInfo = showAllInfo
            }

            public func body(content: Content) -> some View {
                content
                    .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
                    .overlay(
                        ZStack {
                            VStack {
                                Spacer()
                                HStack {
                                    Text(participant.name)
                                        .foregroundColor(.white)
                                        .bold()
                                    Spacer()
                                    ConnectionQualityIndicator(
                                        connectionQuality: participant.connectionQuality
                                    )
                                }
                                .padding(.bottom, 2)
                            }
                            .padding()
                        }
                        .modifier(VideoCallParticipantSpeakingModifier(participant: participant, participantCount: 1))
                    )
            }
        }

        class CustomViewFactory: ViewFactory {

            func makeVideoCallParticipantModifier(
                participant: CallParticipant,
                call: Call?,
                availableFrame: CGRect,
                ratio: CGFloat,
                showAllInfo: Bool
            ) -> some ViewModifier {
                CustomParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: availableFrame,
                    ratio: ratio,
                    showAllInfo: showAllInfo
                )
            }
        }
    }
}
