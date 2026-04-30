//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

/// ViewModifier wrapper so `demoExtendedMenu` can be toggled via `applyDemoDecorationModifierIfRequired`.
struct DemoExtendedParticipantOptionsOverlayModifier: ViewModifier {

    var participant: CallParticipant
    var call: Call?

    func body(content: Content) -> some View {
        content
            .overlay(
                TopLeftView {
                    Group {
                        if let activeCall = call {
                            DemoExtendedParticipantOptionsView(
                                participant: participant,
                                call: activeCall
                            )
                        } else {
                            EmptyView()
                        }
                    }
                }
                .padding(4)
            )
    }
}
