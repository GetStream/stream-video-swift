//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct LobbyView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var viewModel: LobbyViewModel
        
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callViewModel: CallViewModel,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobby: @escaping () -> Void
    ) {
        self.viewFactory = viewFactory
        viewModel = LobbyViewModel(
            callType: callType,
            callId: callId,
            callViewModel: callViewModel,
            onJoinCallTap: onJoinCallTap,
            onCloseLobbyTap: onCloseLobby
        )
    }
    
    public var body: some View {
        VStack {
            headerView
            middleView
            footerView
        }
        .padding()
        .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
        }
    }

    @ViewBuilder
    var headerView: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    viewModel.didTapClose()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(colors.text)
                }
            }

            VStack(alignment: .center) {
                Text(L10n.WaitingRoom.title)
                    .font(.title)
                    .foregroundColor(colors.text)
                    .bold()

                Text(L10n.WaitingRoom.subtitle)
                    .font(.body)
                    .foregroundColor(Color(colors.textLowEmphasis))
            }
        }
        .padding()
        .zIndex(1)
    }

    @ViewBuilder
    var middleView: some View {
        CameraCheckView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )

        SilentMicrophoneIndicator(viewModel: viewModel)

        CallSettingsView(viewModel: viewModel)
    }

    @ViewBuilder
    var footerView: some View {
        JoinCallView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )
        .layoutPriority(2)
    }
}
