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
        struct CustomView: View {
            var body: some View {
                YourView()
                    .background(CallBackground(imageURL: imageURL))
            }
        }
    }
}
