//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        struct CustomView: View {
            var body: some View {
                VStack {
                    UserAvatar(imageURL: participant.profileImageURL, size: 40)
                    SomeOtherView()
                }
            }
        }
    }
}
