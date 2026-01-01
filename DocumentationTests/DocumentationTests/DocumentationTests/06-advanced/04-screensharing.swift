//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        Task {
            let call = streamVideo.call(callType: "default", callId: "123")
            try await call.join()
            try await call.startScreensharing(type: .inApp)
        }
    }

    asyncContainer {
        Task {
            let call = streamVideo.call(callType: "default", callId: "123")
            try await call.join()
            try await call.startScreensharing(type: .inApp, includeAudio: true)
        }
    }

    asyncContainer {
        Task {
            try await call.stopScreensharing()
        }
    }

    viewContainer {
        VideoRendererView(
            id: "\(participant.id)-screenshare",
            size: videoSize,
            contentMode: .scaleAspectFit
        ) { view in
            if let track = participant.screenshareTrack {
                log.debug("adding screensharing track to a view \(view)")
                view.add(track: track)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            func makeScreenSharingView(
                viewModel: CallViewModel,
                screensharingSession: ScreenSharingSession,
                availableFrame: CGRect
            ) -> some View {
                CustomScreenSharingView(
                    viewModel: viewModel,
                    screenSharing: screensharingSession,
                    availableFrame: availableFrame
                )
            }
        }
    }

    viewContainer {
        ScreenshareIconView(viewModel: viewModel)
    }

    viewContainer {
        BroadcastIconView(
            viewModel: viewModel,
            preferredExtension: "bundle_id_of_broadcast_upload_extension"
        )
    }

    container {
        struct BroadcastIconView: View {

            var call: Call
            @StateObject var broadcastObserver = BroadcastObserver()
            let size: CGFloat
            let preferredExtension: String

            public init(
                call: Call,
                preferredExtension: String,
                size: CGFloat = 50
            ) {
                self.call = call
                self.preferredExtension = preferredExtension
                self.size = size
            }

            public var body: some View {
                BroadcastPickerView(
                    preferredExtension: preferredExtension
                )
                .onChange(of: broadcastObserver.broadcastState, perform: { newValue in
                    if newValue == .started {
                        startScreensharing()
                    } else if newValue == .finished {
                        stopScreensharing()
                    }
                })
                .onAppear {
                    broadcastObserver.observe()
                }
            }

            private func startScreensharing() {
                Task {
                    try await call.startScreensharing(type: .broadcast)
                }
            }

            private func stopScreensharing() {
                Task {
                    try await call.stopScreensharing()
                }
            }
        }
    }
}
