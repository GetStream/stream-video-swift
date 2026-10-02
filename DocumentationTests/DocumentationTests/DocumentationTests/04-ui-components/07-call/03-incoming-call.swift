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
            var callInfo: IncomingCall

            public var body: some View {
                IncomingCallView(
                    callInfo: callInfo,
                    onCallAccepted: { _ in
                        // handle call accepted
                    }, onCallRejected: { _ in
                        // handle call rejected
                    }
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
                CustomIncomingCallView(viewModel: viewModel, callInfo: callInfo)
            }
        }
    }

    container {
        let sounds = Sounds()
        sounds.incomingCallSound = "your_sounds.m4a"
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
