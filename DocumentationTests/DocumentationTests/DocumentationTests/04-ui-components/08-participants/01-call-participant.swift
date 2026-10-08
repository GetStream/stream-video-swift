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

            public func makeVideoParticipantView(options: VideoParticipantViewOptions) -> some View {
                VideoCallParticipantView(
                    participant: options.participant,
                    id: options.id,
                    availableFrame: options.availableFrame,
                    contentMode: options.contentMode,
                    customData: options.customData,
                    call: options.call
                )
            }

            public func makeVideoCallParticipantModifier(options: VideoCallParticipantModifierOptions) -> some ViewModifier {
                VideoCallParticipantModifier(
                    participant: options.participant,
                    call: options.call,
                    availableFrame: options.availableFrame,
                    ratio: options.ratio,
                    showAllInfo: options.showAllInfo
                )
            }
        }
    }
}
