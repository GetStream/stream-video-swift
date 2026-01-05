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
        LivestreamPlayer(type: "livestream", id: "some_id")
    }

    viewContainer {
        NavigationLink {
            LivestreamPlayer(type: "livestream", id: "vQyteZAnDYYk")
        } label: {
            Text("Join stream")
        }
    }
}
