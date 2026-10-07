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
                CallView(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeCallView(options: CallViewOptions) -> some View {
                CustomCallView(viewFactory: self, viewModel: options.viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            func makeCallControlsView(options: CallControlsViewOptions) -> some View {
                CustomCallControlsView(viewModel: options.viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoParticipantsView(options: VideoParticipantsViewOptions) -> some View {
                VideoParticipantsView(
                    viewFactory: self,
                    viewModel: options.viewModel,
                    availableFrame: options.availableFrame,
                    onChangeTrackVisibility: options.onChangeTrackVisibility
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoParticipantView(options: VideoParticipantViewOptions) -> some View {
                VideoCallParticipantView(
                    participant: options.participant,
                    id: options.id,
                    availableFrame: options.availableFrame,
                    contentMode: options.contentMode,
                    customData: options.customData,
                    call: options.call
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoCallParticipantModifier(options: VideoCallParticipantModifierOptions) -> some ViewModifier {
                VideoCallParticipantModifier(
                    participant: options.participant,
                    call: options.call,
                    availableFrame: options.availableFrame,
                    ratio: options.ratio,
                    showAllInfo: options.showAllInfo
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeCallTopView(options: CallTopViewOptions) -> some View {
                CallTopView(viewModel: options.viewModel)
            }
        }
    }
}
