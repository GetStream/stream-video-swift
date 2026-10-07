//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

final class DemoAppViewFactory: ViewFactory {

    static let shared = DemoAppViewFactory()

    @Injected(\.snapshotTrigger) var snapshotTrigger
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors
    @Injected(\.layout) var layout

    func makeWaitingLocalUserView(options: WaitingLocalUserViewOptions) -> some View {
        DemoWaitingLocalUserView(viewFactory: self, viewModel: options.viewModel)
    }

    @ViewBuilder
    func makeLobbyView(options: LobbyViewOptions) -> some View {
        let viewModel = options.viewModel
        let lobbyInfo = options.lobbyInfo
        let handleJoinCall = { [streamVideo] in
            guard case .lobby = viewModel.callingState else { return }
            Task { @MainActor [streamVideo] in
                let keys = AppEnvironment.EncryptionKeys.shared
                let call = streamVideo.call(
                    callType: lobbyInfo.callType,
                    callId: lobbyInfo.callId
                )
                await keys.attachIfNeeded(to: call, userId: streamVideo.user.id)
                viewModel.startCall(
                    callType: lobbyInfo.callType,
                    callId: lobbyInfo.callId,
                    members: lobbyInfo.participants,
                    encryption: keys.encryptionRequest
                )
            }
        }
        let handleCloseLobby = {
            viewModel.hangUp()
        }

        LobbyView(
            viewFactory: self,
            callId: lobbyInfo.callId,
            callType: lobbyInfo.callType,
            callSettings: options.callSettings,
            callSettingsView: { DemoCallSettingsView(callSettings: $0) },
            onJoinCallTap: handleJoinCall,
            onCloseLobby: handleCloseLobby
        )
        .alignedToReadableContentGuide()
        .background(Color(colors.backgroundCoreApp).edgesIgnoringSafeArea(.all))
    }

    func makeInnerWaitingLocalUserView(viewModel: CallViewModel) -> AnyView {
        .init(WaitingLocalUserView(viewModel: viewModel, viewFactory: self))
    }

    func makeCallView(options: CallViewOptions) -> DemoCallView<DemoAppViewFactory> {
        DemoCallView(
            viewFactory: self,
            viewModel: options.viewModel
        )
    }

    func makeInnerCallView(viewModel: CallViewModel) -> AnyView {
        .init(StreamVideoSwiftUI.CallView(viewFactory: self, viewModel: viewModel))
    }

    func makeCallControlsView(options: CallControlsViewOptions) -> some View {
        AppControlsWithChat(viewModel: options.viewModel)
    }

    func makeCallTopView(options: CallTopViewOptions) -> some View {
        DemoCallTopView(viewFactory: self, viewModel: options.viewModel)
    }

    func makeVideoCallParticipantModifier(options: VideoCallParticipantModifierOptions) -> some ViewModifier {
        DemoVideoCallParticipantModifier(
            participant: options.participant,
            call: options.call,
            availableFrame: options.availableFrame,
            ratio: options.ratio,
            showAllInfo: options.showAllInfo
        )
    }

    func makeLocalParticipantViewModifier(options: LocalParticipantViewModifierOptions) -> some ViewModifier {
        DemoLocalViewModifier(
            localParticipant: options.localParticipant,
            callSettings: options.callSettings,
            call: options.call
        )
    }

    func makeVideoParticipantsView(options: VideoParticipantsViewOptions) -> some View {
        let viewModel = options.viewModel
        return VideoParticipantsView(
            viewFactory: self,
            viewModel: viewModel,
            availableFrame: options.availableFrame,
            onChangeTrackVisibility: options.onChangeTrackVisibility
        )
        .snapshot(trigger: snapshotTrigger) { [weak viewModel] snapshot in
            Task { @MainActor [weak viewModel] in
                viewModel?.sendSnapshot(snapshot)
            }
        }
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                DemoClosedCaptionsView(viewModel)
                    .padding(.bottom, layout.spacing2xl)
            }
        )
    }
}
