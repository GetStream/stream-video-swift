//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoParticipantOptionsButton: View {

    @Injected(\.appearance) var appearance
    var action: () -> Void = {}

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(appearance.colors.white)
                .padding(8)
                .background(appearance.colors.participantInfoBackgroundColor)
                .clipShape(Circle())
        }
    }
}
