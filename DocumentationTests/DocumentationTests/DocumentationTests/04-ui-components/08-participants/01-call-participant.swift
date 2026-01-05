//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    viewContainer {
        VideoCallParticipantView(
            participant: participant,
            id: id,
            availableFrame: availableFrame,
            contentMode: contentMode,
            customData: customData,
            call: call
        )
        .modifier(
            VideoCallParticipantModifier(
                participant: participant,
                call: call,
                availableFrame: availableFrame,
                ratio: ratio,
                showAllInfo: true
            )
        )
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoParticipantView(
                participant: CallParticipant,
                id: String,
                availableFrame: CGRect,
                contentMode: UIView.ContentMode,
                customData: [String: RawJSON],
                call: Call?
            ) -> some View {
                VideoCallParticipantView(
                    participant: participant,
                    id: id,
                    availableFrame: availableFrame,
                    contentMode: contentMode,
                    customData: customData,
                    call: call
                )
            }

            public func makeVideoCallParticipantModifier(
                participant: CallParticipant,
                call: Call?,
                availableFrame: CGRect,
                ratio: CGFloat,
                showAllInfo: Bool
            ) -> some ViewModifier {
                VideoCallParticipantModifier(
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
