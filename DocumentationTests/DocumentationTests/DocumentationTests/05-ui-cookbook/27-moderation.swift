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
        struct CallContainer<Factory: ViewFactory>: View {
            @StateObject var viewModel: CallViewModel

            var body: some View {
                Group {
                    // Body content
                    // ...
                }
                .moderationWarning(call: viewModel.call)
            }
        }
    }

    container {
        let call = streamVideo.call(callType: "default", callId: "my-call-id")
        let videoPolicy = Moderation.VideoPolicy(duration: 10, videoFilter: .blur)
        call.moderation.setVideoPolicy(videoPolicy)
    }
}
