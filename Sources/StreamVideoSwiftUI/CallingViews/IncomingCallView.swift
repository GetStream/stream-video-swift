//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

/// A SwiftUI view for displaying an incoming call screen.
@available(iOS 14.0, *)
public struct IncomingCallView<Factory: ViewFactory>: View {

    @Injected(\.utils) var utils

    var viewFactory: Factory
    @StateObject var viewModel: IncomingViewModel

    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void

    /// Initializes the incoming call view with call information
    /// and callbacks for call acceptance and rejection.
    /// - Parameters:
    ///   - callInfo: Information about the incoming call.
    ///   - onCallAccepted: Callback when the incoming call is
    ///     accepted.
    ///   - onCallRejected: Callback when the incoming call is
    ///     rejected.
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callInfo: IncomingCall,
        onCallAccepted: @escaping (String) -> Void,
        onCallRejected: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: IncomingViewModel(callInfo: callInfo)
        )
        self.viewFactory = viewFactory
        self.onCallAccepted = onCallAccepted
        self.onCallRejected = onCallRejected
    }

    public var body: some View {
        IncomingCallViewContent(
            viewFactory: viewFactory,
            callParticipants: viewModel.callParticipants,
            callInfo: viewModel.callInfo,
            onCallAccepted: onCallAccepted,
            onCallRejected: onCallRejected
        )
    }
}

/// The content view of the incoming call screen.
struct IncomingCallViewContent<Factory: ViewFactory>: View {

    @Injected(\.utils) var utils
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    var viewFactory: Factory
    var callParticipants: [Member]
    var callInfo: IncomingCall
    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void

    var body: some View {
        VStack(spacing: layout.spacingMd) {
            Spacer()

            if callParticipants.count > 1 {
                CallingGroupView(
                    viewFactory: viewFactory,
                    participants: callParticipants
                )
            } else {
                AnimatingParticipantView(
                    viewFactory: viewFactory,
                    participant: callParticipants.first,
                    caller: callInfo.caller.name
                )
            }

            CallingParticipantsView(
                participants: callParticipants,
                caller: callInfo.caller.name
            )
            .padding(layout.spacingMd)

            HStack(alignment: .firstTextBaseline, spacing: layout.spacingXxxs) {
                Text(L10n.Call.Incoming.title)
                    .font(fonts.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        Color(colors.textSecondary)
                    )
                CallingIndicator()
            }

            Spacer()

            HStack(spacing: layout.spacingXs) {
                Spacing()

                Button {
                    onCallRejected(callInfo.id)
                } label: {
                    images.declineCall
                        .applyCallButtonStyle(
                            color: Color(
                                colors
                                    .controlDeclineCallButtonBackground
                            ),
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, layout.spacingXs)

                Spacing(size: 3)

                Button {
                    onCallAccepted(callInfo.id)
                } label: {
                    images.acceptCall
                        .applyCallButtonStyle(
                            color: Color(
                                colors
                                    .controlAcceptCallButtonBackground
                            ),
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, layout.spacingXs)

                Spacing()
            }
            .padding(layout.spacingMd)
        }
        .background(
            CallBackground()
        )
        .onAppear {
            utils.callSoundsPlayer.playIncomingCallSound()
        }
        .onDisappear {
            utils.callSoundsPlayer.stopOngoingSound()
        }
    }
}
