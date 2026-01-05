//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "my-call-id")
        await call.disableClientCapabilities([.subscriberVideoPause])
    }

    container {
        let cancellable = call
            .state
            .$participants
            .sink { participants in
                let pausedVideoParticipants = participants.filter {
                    $0.pausedTracks.contains(.video)
                }

                print("Participants with paused video tracks: \(pausedVideoParticipants)")
            }

        // Cancel when no longer needed:
        cancellable.cancel()
    }

    viewContainer {
        if participant.pausedTracks.contains(.video) {
            Image(systemName: "video.slash.fill")
                .foregroundColor(.yellow)
                .padding(4)
        }
    }

    container {
        struct ParticipantInfoView: View {
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

                    if participant.pausedTracks.contains(.video) {
                        Image(systemName: "wifi.slash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: maxHeight)
                            .foregroundColor(.white)
                            .padding(.trailing, 4)
                    }

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
    }

    container {
        struct VideoCallParticipantModifier: ViewModifier {

            var participant: CallParticipant
            var call: Call?
            var availableFrame: CGRect
            var ratio: CGFloat
            var showAllInfo: Bool
            var decorations: Set<VideoCallParticipantDecoration>

            public init(
                participant: CallParticipant,
                call: Call?,
                availableFrame: CGRect,
                ratio: CGFloat,
                showAllInfo: Bool,
                decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
            ) {
                self.participant = participant
                self.call = call
                self.availableFrame = availableFrame
                self.ratio = ratio
                self.showAllInfo = showAllInfo
                self.decorations = .init(decorations)
            }

            public func body(content: Content) -> some View {
                content
                    .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
                    .overlay(
                        ZStack {
                            BottomView(content: {
                                HStack {
                                    ParticipantInfoView(
                                        participant: participant,
                                        isPinned: participant.isPinned
                                    )

                                    Spacer()

                                    if showAllInfo {
                                        ConnectionQualityIndicator(
                                            connectionQuality: participant.connectionQuality
                                        )
                                    }
                                }
                            })
                        }
                    )
                    .applyDecorationModifierIfRequired(
                        VideoCallParticipantOptionsModifier(participant: participant, call: call),
                        decoration: .options,
                        availableDecorations: decorations
                    )
                    .applyDecorationModifierIfRequired(
                        VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantCount),
                        decoration: .speaking,
                        availableDecorations: decorations
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .clipped()
            }

            @MainActor
            private var participantCount: Int {
                call?.state.participants.count ?? 0
            }
        }
    }
}
