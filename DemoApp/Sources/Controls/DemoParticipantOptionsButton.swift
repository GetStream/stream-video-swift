//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

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
