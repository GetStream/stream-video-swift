//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A SwiftUI view for displaying an incoming call screen.
@available(iOS 14.0, *)
public struct IncomingCallView<Factory: ViewFactory>: View {

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.utils) var utils

    var viewFactory: Factory
    @StateObject var viewModel: IncomingViewModel

    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void

    /// Initializes the incoming call view with call information and callbacks for call acceptance and rejection.
    /// - Parameters:
    ///   - callInfo: Information about the incoming call.
    ///   - onCallAccepted: Callback when the incoming call is accepted.
    ///   - onCallRejected: Callback when the incoming call is rejected.
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

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.utils) var utils

    var viewFactory: Factory
    var callParticipants: [Member]
    var callInfo: IncomingCall
    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
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
            .padding()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(L10n.Call.Incoming.title)
                    .applyCallingStyle()
                CallingIndicator()
            }

            Spacer()

            HStack {
                Spacing()

                Button {
                    onCallRejected(callInfo.id)
                } label: {
                    Image(systemName: "phone.down.circle.fill")
                        .applyCallButtonStyle(
                            color: Color.red,
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, 8)

                Spacing(size: 3)

                Button {
                    onCallAccepted(callInfo.id)
                } label: {
                    images.acceptCall
                        .applyCallButtonStyle(
                            color: Color.green,
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, 8)

                Spacing()
            }
            .padding()
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
