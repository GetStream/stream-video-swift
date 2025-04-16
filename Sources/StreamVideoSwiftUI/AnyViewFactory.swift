//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public final class AnyViewFactory: ViewFactory {

    private let _makeCallControlsView: (CallViewModel) -> AnyView
    private let _makeOutgoingCallView: (CallViewModel) -> AnyView
    private let _makeJoiningCallView: (CallViewModel) -> AnyView
    private let _makeIncomingCallView: (CallViewModel, IncomingCall) -> AnyView
    private let _makeWaitingLocalUserView: (CallViewModel) -> AnyView
    private let _makeVideoParticipantsView: (
        CallViewModel,
        CGRect,
        @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> AnyView
    private let _makeVideoParticipantView: (
        CallParticipant,
        String,
        CGRect,
        UIView.ContentMode,
        [String: RawJSON],
        Call?
    ) -> AnyView
    private let _makeVideoCallParticipantModifier: (
        CallParticipant,
        Call?,
        CGRect,
        CGFloat,
        Bool
    ) -> any ViewModifier
    private let _makeCallView: (CallViewModel) -> AnyView
    private let _makeMinimizedCallView: (CallViewModel) -> AnyView
    private let _makeCallTopView: (CallViewModel) -> AnyView
    private let _makeParticipantsListView: (CallViewModel) -> AnyView
    private let _makeScreenSharingView: (CallViewModel, ScreenSharingSession, CGRect) -> AnyView
    private let _makeLobbyView: (CallViewModel, LobbyInfo, Binding<CallSettings>) -> AnyView
    private let _makeReconnectionView: (CallViewModel) -> AnyView
    private let _makeLocalParticipantViewModifier: (
        CallParticipant,
        Binding<CallSettings>,
        Call?
    ) -> any ViewModifier
    private let _makeUserAvatar: (User, UserAvatarViewOptions) -> AnyView

    public init<T: ViewFactory>(_ factory: T) {
        _makeCallControlsView = { AnyView(factory.makeCallControlsView(viewModel: $0)) }
        _makeOutgoingCallView = { AnyView(factory.makeOutgoingCallView(viewModel: $0)) }
        _makeJoiningCallView = { AnyView(factory.makeJoiningCallView(viewModel: $0)) }
        _makeIncomingCallView = { AnyView(factory.makeIncomingCallView(viewModel: $0, callInfo: $1)) }
        _makeWaitingLocalUserView = { AnyView(factory.makeWaitingLocalUserView(viewModel: $0)) }
        _makeVideoParticipantsView = {
            AnyView(factory.makeVideoParticipantsView(viewModel: $0, availableFrame: $1, onChangeTrackVisibility: $2))
        }
        _makeVideoParticipantView = {
            AnyView(
                factory
                    .makeVideoParticipantView(
                        participant: $0,
                        id: $1,
                        availableFrame: $2,
                        contentMode: $3,
                        customData: $4,
                        call: $5
                    )
            )
        }
        _makeVideoCallParticipantModifier = {
            factory.makeVideoCallParticipantModifier(
                participant: $0,
                call: $1,
                availableFrame: $2,
                ratio: $3,
                showAllInfo: $4
            )
        }
        _makeCallView = { AnyView(factory.makeCallView(viewModel: $0)) }
        _makeMinimizedCallView = { AnyView(factory.makeMinimizedCallView(viewModel: $0)) }
        _makeCallTopView = { AnyView(factory.makeCallTopView(viewModel: $0)) }
        _makeParticipantsListView = { AnyView(factory.makeParticipantsListView(viewModel: $0)) }
        _makeScreenSharingView = {
            AnyView(factory.makeScreenSharingView(viewModel: $0, screensharingSession: $1, availableFrame: $2))
        }
        _makeLobbyView = { AnyView(factory.makeLobbyView(viewModel: $0, lobbyInfo: $1, callSettings: $2)) }
        _makeReconnectionView = { AnyView(factory.makeReconnectionView(viewModel: $0)) }
        _makeLocalParticipantViewModifier = {
            factory.makeLocalParticipantViewModifier(localParticipant: $0, callSettings: $1, call: $2)
        }
        _makeUserAvatar = { AnyView(factory.makeUserAvatar($0, with: $1)) }
    }

    public func makeCallControlsView(viewModel: CallViewModel) -> some View {
        _makeCallControlsView(viewModel)
    }

    public func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
        _makeOutgoingCallView(viewModel)
    }

    public func makeJoiningCallView(viewModel: CallViewModel) -> some View {
        _makeJoiningCallView(viewModel)
    }

    public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
        _makeIncomingCallView(viewModel, callInfo)
    }

    public func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        _makeWaitingLocalUserView(viewModel)
    }

    public func makeVideoParticipantsView(
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> some View {
        _makeVideoParticipantsView(viewModel, availableFrame, onChangeTrackVisibility)
    }

    public func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        call: Call?
    ) -> some View {
        _makeVideoParticipantView(participant, id, availableFrame, contentMode, customData, call)
    }

    public func makeVideoCallParticipantModifier(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool
    ) -> any ViewModifier {
        _makeVideoCallParticipantModifier(participant, call, availableFrame, ratio, showAllInfo)
    }

    public func makeCallView(viewModel: CallViewModel) -> some View {
        _makeCallView(viewModel)
    }

    public func makeMinimizedCallView(viewModel: CallViewModel) -> some View {
        _makeMinimizedCallView(viewModel)
    }

    public func makeCallTopView(viewModel: CallViewModel) -> some View {
        _makeCallTopView(viewModel)
    }

    public func makeParticipantsListView(viewModel: CallViewModel) -> some View {
        _makeParticipantsListView(viewModel)
    }

    public func makeScreenSharingView(
        viewModel: CallViewModel,
        screensharingSession: ScreenSharingSession,
        availableFrame: CGRect
    ) -> some View {
        _makeScreenSharingView(viewModel, screensharingSession, availableFrame)
    }

    public func makeLobbyView(
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) -> some View {
        _makeLobbyView(viewModel, lobbyInfo, callSettings)
    }

    public func makeReconnectionView(viewModel: CallViewModel) -> some View {
        _makeReconnectionView(viewModel)
    }

    public func makeLocalParticipantViewModifier(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>,
        call: Call?
    ) -> any ViewModifier {
        _makeLocalParticipantViewModifier(localParticipant, callSettings, call)
    }

    public func makeUserAvatar(
        _ user: User,
        with options: UserAvatarViewOptions
    ) -> some View {
        _makeUserAvatar(user, options)
    }
}
