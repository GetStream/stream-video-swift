//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoParticipantOptionsButton: View {

    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.layout) var layout
    var action: () -> Void = {}

    var body: some View {
        Button {
            action()
        } label: {
            images.participantOptions
                .foregroundColor(Color(colors.textOnAccent))
                .padding(layout.spacingXs)
                .background(Color(colors.backgroundCoreOverlayDarkStrong))
                .clipShape(Circle())
        }
    }
}
