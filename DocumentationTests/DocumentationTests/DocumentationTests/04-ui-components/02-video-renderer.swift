//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC
import SwiftUI

@MainActor
private func content() {
    viewContainer {
        VideoRendererView(
            id: id,
            size: availableSize,
            contentMode: contentMode
        ) { view in
            view.handleViewRendering(for: participant) { _, _ in
                // handle track size update
            }
        }
    }

    container {
        final class CustomObject: UIView {

            func add(track: RTCVideoTrack) {}

            func handleViewRendering(
                for participant: CallParticipant,
                onTrackSizeUpdate: @escaping (CGSize, CallParticipant) -> Void
            ) {
                if let track = participant.track {
                    log.debug("adding track to a view \(self)")
                    self.add(track: track)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        let prev = participant.trackSize
                        let scale = UIScreen.main.scale
                        let newSize = CGSize(
                            width: self.bounds.size.width * scale,
                            height: self.bounds.size.height * scale
                        )
                        if prev != newSize {
                            onTrackSizeUpdate(newSize, participant)
                        }
                    }
                }
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

        viewContainer {
            ForEach(participants) { participant in
                viewFactory.makeVideoParticipantView(
                    participant: participant,
                    id: participant.id,
                    availableFrame: availableFrame,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: call
                )
                .modifier(
                    viewFactory.makeVideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableFrame: availableFrame,
                        ratio: ratio,
                        showAllInfo: true
                    )
                )
            }
        }
    }
}
