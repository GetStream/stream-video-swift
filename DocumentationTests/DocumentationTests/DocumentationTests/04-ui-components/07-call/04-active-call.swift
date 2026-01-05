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

            public func makeCallView(viewModel: CallViewModel) -> some View {
                CustomCallView(viewFactory: self, viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            func makeCallControlsView(viewModel: CallViewModel) -> some View {
                CustomCallControlsView(viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoParticipantsView(
                viewModel: CallViewModel,
                availableFrame: CGRect,
                onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
            ) -> some View {
                VideoParticipantsView(
                    viewFactory: self,
                    viewModel: viewModel,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoParticipantView(
                participant: CallParticipant,
                id: String,
                availableFrame: CGRect,
                contentMode: UIView.ContentMode,
                customData: [String: RawJSON],
                call: Call?
            ) -> some View {
                VideoCallParticipantView(
                    participant: participant,
                    id: id,
                    availableFrame: availableFrame,
                    contentMode: contentMode,
                    customData: customData,
                    call: call
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeVideoCallParticipantModifier(
                participant: CallParticipant,
                call: Call?,
                availableFrame: CGRect,
                ratio: CGFloat,
                showAllInfo: Bool
            ) -> some ViewModifier {
                VideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: availableFrame,
                    ratio: ratio,
                    showAllInfo: showAllInfo
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            public func makeCallTopView(viewModel: CallViewModel) -> some View {
                CallTopView(viewModel: viewModel)
            }
        }
    }
}
