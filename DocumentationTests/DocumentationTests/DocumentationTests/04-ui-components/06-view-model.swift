import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    viewContainer {
        Button {
            viewModel.startCall(callType: "default", callId: callId, members: members, ring: false)
        } label: {
            Text("Start a call")
        }
    }

    viewContainer {
        Button {
            viewModel.joinCall(callType: "default", callId: callId)
        } label: {
            Text("Join a call")
        }
    }
}
