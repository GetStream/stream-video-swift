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
        class CustomViewFactory: ViewFactory {

            func makeVideoParticipantView(
                participant: CallParticipant,
                id: String,
                availableFrame: CGRect,
                contentMode: UIView.ContentMode,
                customData: [String: RawJSON],
                call: Call?
            ) -> some View {
                CustomVideoCallParticipantView(
                    participant: participant,
                    id: id,
                    availableFrame: availableFrame,
                    contentMode: contentMode,
                    call: call
                )
            }
        }

        struct CustomVideoCallParticipantView: View {

            @Injected(\.images) var images
            @Injected(\.streamVideo) var streamVideo

            let participant: CallParticipant
            var id: String
            var availableFrame: CGRect
            var contentMode: UIView.ContentMode
            var edgesIgnoringSafeArea: Edge.Set
            var call: Call?

            public init(
                participant: CallParticipant,
                id: String? = nil,
                availableFrame: CGRect,
                contentMode: UIView.ContentMode,
                edgesIgnoringSafeArea: Edge.Set = .all,
                call: Call?
            ) {
                self.participant = participant
                self.id = id ?? participant.id
                self.availableFrame = availableFrame
                self.contentMode = contentMode
                self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
                self.call = call
            }

            public var body: some View {
                VideoRendererView(
                    id: id,
                    size: availableFrame.size,
                    contentMode: contentMode,
                    handleRendering: { view in
                        view.handleViewRendering(for: participant) { size, participant in
                            Task {
                                await call?.updateTrackSize(size, for: participant)
                            }
                        }
                    }
                )
                .opacity(showVideo ? 1 : 0)
                .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
                .accessibility(identifier: "callParticipantView")
                .streamAccessibility(value: showVideo ? "1" : "0")
                .overlay(
                    CallParticipantImageView(
                        id: participant.id,
                        name: participant.name,
                        imageURL: participant.profileImageURL
                    )
                    .frame(width: availableFrame.size.width)
                    .opacity(showVideo ? 0 : 1)
                )
            }

            private var showVideo: Bool {
                participant.shouldDisplayTrack || customData["videoOn"]?.boolValue == true
            }
        }
    }
}
