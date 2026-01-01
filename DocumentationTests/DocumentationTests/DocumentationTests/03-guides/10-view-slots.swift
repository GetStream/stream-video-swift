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
        class CustomViewFactory: ViewFactory {

            struct CustomOutgoingCallView: View {
                var viewModel: CallViewModel
                
                @ViewBuilder
                var body: some View {
                    EmptyView()
                }
            }

            func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
                CustomOutgoingCallView(viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            struct CustomIncomingCallView: View {
                var callInfo: IncomingCall
                var viewModel: CallViewModel

                @ViewBuilder
                var body: some View {
                    EmptyView()
                }
            }

            public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
                CustomIncomingCallView(callInfo: callInfo, viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            struct CustomCallView: View {
                var viewModel: CallViewModel

                @ViewBuilder
                var body: some View {
                    EmptyView()
                }
            }

            public func makeCallView(viewModel: CallViewModel) -> some View {
                CustomCallView(viewModel: viewModel)
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            struct CustomCallControlsView: View {
                var viewModel: CallViewModel

                @ViewBuilder
                var body: some View {
                    EmptyView()
                }
            }

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

            func makeVideoParticipantView(
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

            struct CallTopView: View {
                var viewModel: CallViewModel

                @ViewBuilder
                var body: some View {
                    EmptyView()
                }
            }

            public func makeCallTopView(viewModel: CallViewModel) -> some View {
                CallTopView(viewModel: viewModel)
            }
        }
    }
}
