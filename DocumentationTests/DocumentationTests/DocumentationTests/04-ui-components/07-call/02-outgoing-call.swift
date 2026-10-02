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
            public var body: some View {
                OutgoingCallView(
                    outgoingCallMembers: outgoingCallMembers,
                    callTopView: callTopView,
                    callControls: callControls
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
                CustomOutgoingCallView(viewModel: viewModel)
            }
        }
    }

    container {
        let sounds = Sounds()
        sounds.outgoingCallSound = "your_sounds.m4a"
        let videoAppearance = VideoAppearance(sounds: sounds)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
    }

    container {
        let images = Images()
        images.hangup = Image("custom_hangup_icon")
        let videoAppearance = VideoAppearance(images: images)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
    }
}
