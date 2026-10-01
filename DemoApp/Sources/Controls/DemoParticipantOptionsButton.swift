//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoParticipantOptionsButton: View {

    @Injected(\.videoAppearance) var videoAppearance
    var action: () -> Void = {}

    var body: some View {
        Button {
            action()
        } label: {
            videoAppearance.images.participantOptions
                .foregroundColor(Color(videoAppearance.tokens.colors.textOnAccent))
                .padding(videoAppearance.tokens.layout.spacingXs)
                .background(Color(videoAppearance.tokens.colors.backgroundCoreOverlayDarkStrong))
                .clipShape(Circle())
        }
    }
}
