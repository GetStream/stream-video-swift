//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

final class DemoAppViewFactory: ViewFactory {

    static let shared = DemoAppViewFactory()

    @Injected(\.colors) var colors
    @Injected(\.snapshotTrigger) var snapshotTrigger

    func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        DemoWaitingLocalUserView(viewFactory: self, viewModel: viewModel)
    }

    func makeLobbyView(
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) -> some View {
        DefaultViewFactory
            .shared
            .makeLobbyView(
                viewModel: viewModel,
                lobbyInfo: lobbyInfo,
                callSettings: callSettings
            )
            .alignedToReadableContentGuide()
            .background(Appearance.default.colors.lobbyBackground.edgesIgnoringSafeArea(.all))
    }

    func makeInnerWaitingLocalUserView(viewModel: CallViewModel) -> AnyView {
        .init(WaitingLocalUserView(viewModel: viewModel, viewFactory: self))
    }

    func makeCallView(viewModel: CallViewModel) -> DemoCallView<DemoAppViewFactory> {
        DemoCallView(
            viewFactory: self,
            microphoneChecker: MicrophoneChecker(),
            viewModel: viewModel
        )
    }

    func makeInnerCallView(viewModel: CallViewModel) -> AnyView {
        .init(StreamVideoSwiftUI.CallView(viewFactory: self, viewModel: viewModel))
    }

    func makeCallControlsView(viewModel: CallViewModel) -> some View {
        AppControlsWithChat(viewModel: viewModel)
    }

    func makeCallTopView(viewModel: CallViewModel) -> some View {
        DemoCallTopView(viewFactory: self, viewModel: viewModel)
    }

    func makeVideoCallParticipantModifier(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool
    ) -> some ViewModifier {
        DemoVideoCallParticipantModifier(
            participant: participant,
            call: call,
            availableFrame: availableFrame,
            ratio: ratio,
            showAllInfo: showAllInfo
        )
    }

    func makeLocalParticipantViewModifier(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>,
        call: Call?
    ) -> some ViewModifier {
        DemoLocalViewModifier(
            localParticipant: localParticipant,
            callSettings: callSettings,
            call: call
        )
    }

    func makeVideoParticipantsView(
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
        .snapshot(trigger: snapshotTrigger) { [weak viewModel] snapshot in
            Task { @MainActor [weak viewModel] in
                viewModel?.sendSnapshot(snapshot)
            }
        }
        .overlay(
            VStack {
                Spacer()
                DemoClosedCaptionsView(viewModel)
                    .padding(.bottom, 30)
            }
        )
    }
}
