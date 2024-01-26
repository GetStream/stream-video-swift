import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
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
