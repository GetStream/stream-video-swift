//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
public protocol ViewFactory: AnyObject {

    associatedtype CallControlsViewType: View = CallControlsView
    /// Creates the call controls view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the call controls slot.
    func makeCallControlsView(options: CallControlsViewOptions) -> CallControlsViewType

    associatedtype OutgoingCallViewType: View
    /// Creates the outgoing call view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the outgoing call slot.
    func makeOutgoingCallView(options: OutgoingCallViewOptions) -> OutgoingCallViewType

    associatedtype JoiningCallViewType: View
    /// Creates the joining call view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the joining call slot.
    func makeJoiningCallView(options: JoiningCallViewOptions) -> JoiningCallViewType

    associatedtype IncomingCallViewType: View
    /// Creates the incoming call view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the incoming call slot.
    func makeIncomingCallView(options: IncomingCallViewOptions) -> IncomingCallViewType

    associatedtype WaitingLocalUserViewType: View
    /// Creates the waiting local user view, shown when the local participant is the only one on the call.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the waiting local user view.
    func makeWaitingLocalUserView(options: WaitingLocalUserViewOptions) -> WaitingLocalUserViewType

    associatedtype ParticipantsViewType: View = VideoParticipantsView<Self>
    /// Creates the video participants view, shown during a call.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the video participants slot.
    func makeVideoParticipantsView(options: VideoParticipantsViewOptions) -> ParticipantsViewType

    associatedtype ParticipantViewType: View = VideoCallParticipantView<Self>
    /// Creates a view for a video call participant.
    /// - Parameter options: The options for creating the view.
    /// - Returns: A view for the specified video call participant.
    func makeVideoParticipantView(options: VideoParticipantViewOptions) -> ParticipantViewType

    associatedtype ParticipantViewModifierType: ViewModifier = VideoCallParticipantModifier
    /// Creates a view modifier that can be used to modify the appearance of the video call participant view.
    /// - Parameter options: The options for creating the modifier.
    /// - Returns: A view modifier that modifies the appearance of the video call participant.
    func makeVideoCallParticipantModifier(
        options: VideoCallParticipantModifierOptions
    ) -> ParticipantViewModifierType

    associatedtype CallViewType: View = CallView<Self>
    /// Creates the call view, shown when a call is in progress.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the call view slot.
    func makeCallView(options: CallViewOptions) -> CallViewType
    
    associatedtype MinimizedCallViewType: View = MinimizedCallView<Self>
    /// Creates the minimized call view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the minimized call view slot.
    func makeMinimizedCallView(options: MinimizedCallViewOptions) -> MinimizedCallViewType

    associatedtype CallTopViewType: View = CallTopView<Self>
    /// Creates a view displayed at the top of the call view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the top call view slot.
    func makeCallTopView(options: CallTopViewOptions) -> CallTopViewType

    associatedtype CallParticipantsListViewType: View
    /// Creates a view that shows a list of the participants in the call.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the participants list slot.
    func makeParticipantsListView(options: ParticipantsListViewOptions) -> CallParticipantsListViewType

    associatedtype ScreenSharingViewType: View
    /// Creates a view shown when there's screen sharing session.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the screensharing slot.
    func makeScreenSharingView(options: ScreenSharingViewOptions) -> ScreenSharingViewType

    associatedtype LobbyViewType: View
    /// Creates the view that's displayed before the user joins the call.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the pre-joining slot.
    func makeLobbyView(options: LobbyViewOptions) -> LobbyViewType

    associatedtype ReconnectionViewType: View
    /// Creates the view shown when the call is reconnecting.
    /// - Parameter options: The options for creating the view.
    /// - Returns: view shown in the reconnection slot.
    func makeReconnectionView(options: ReconnectionViewOptions) -> ReconnectionViewType

    associatedtype LocalParticipantViewModifierType: ViewModifier
    /// Creates a view modifier for the local participant view.
    /// - Parameter options: The options for creating the modifier.
    /// - Returns: A view modifier for the local participant view.
    func makeLocalParticipantViewModifier(
        options: LocalParticipantViewModifierOptions
    ) -> LocalParticipantViewModifierType

    associatedtype UserAvatarViewType: View
    /// Creates a user avatar view.
    /// - Parameter options: The options for creating the view.
    /// - Returns: A view representing the user's avatar.
    func makeUserAvatar(options: UserAvatarViewOptions) -> UserAvatarViewType

    associatedtype PermissionsPromptViewType: View
    /// Creates a prompt that asks the user to accept missing permissions.
    /// - Parameter options: The options for creating the view.
    /// - Returns: A view asking the user to grant missing permissions.
    func makePermissionsPromptView(options: PermissionsPromptViewOptions) -> PermissionsPromptViewType
}

extension ViewFactory {

    public func makeCallControlsView(options: CallControlsViewOptions) -> some View {
        CallControlsView(viewModel: options.viewModel)
    }

    public func makeOutgoingCallView(options: OutgoingCallViewOptions) -> some View {
        let viewModel = options.viewModel
        var membersToShow = viewModel.outgoingCallMembers.isEmpty
            ? (viewModel.streamVideo.state.ringingCall?.state.members ?? viewModel.outgoingCallMembers)
            : viewModel.outgoingCallMembers

        // Remove the current user from the ringing members
        membersToShow = membersToShow.filter {
            viewModel.streamVideo.user.id != $0.user.id
        }

        return OutgoingCallView(
            viewFactory: self,
            outgoingCallMembers: membersToShow,
            callTopView: makeCallTopView(options: .init(viewModel: viewModel)),
            callControls: makeCallControlsView(options: .init(viewModel: viewModel))
        )
    }

    public func makeJoiningCallView(options: JoiningCallViewOptions) -> some View {
        JoiningCallView(
            viewFactory: self,
            callTopView: makeCallTopView(options: .init(viewModel: options.viewModel)),
            callControls: makeCallControlsView(options: .init(viewModel: options.viewModel))
        )
    }

    public func makeIncomingCallView(options: IncomingCallViewOptions) -> some View {
        let viewModel = options.viewModel
        let callInfo = options.callInfo
        if #available(iOS 14.0, *) {
            return IncomingCallView(
                viewFactory: self,
                callInfo: callInfo,
                onCallAccepted: { _ in
                    viewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
                },
                onCallRejected: { _ in
                    viewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
                }
            )
        } else {
            return IncomingCallView_iOS13(
                viewFactory: self,
                callInfo: callInfo,
                onCallAccepted: { _ in
                    viewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
                },
                onCallRejected: { _ in
                    viewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
                }
            )
        }
    }

    public func makeWaitingLocalUserView(options: WaitingLocalUserViewOptions) -> some View {
        WaitingLocalUserView(viewModel: options.viewModel, viewFactory: self)
    }

    public func makeVideoParticipantsView(options: VideoParticipantsViewOptions) -> some View {
        VideoParticipantsView(
            viewFactory: self,
            viewModel: options.viewModel,
            availableFrame: options.availableFrame,
            onChangeTrackVisibility: options.onChangeTrackVisibility
        )
    }

    public func makeVideoParticipantView(options: VideoParticipantViewOptions) -> some View {
        VideoCallParticipantView(
            viewFactory: self,
            participant: options.participant,
            id: options.id,
            availableFrame: options.availableFrame,
            contentMode: options.contentMode,
            customData: options.customData,
            call: options.call
        )
    }

    public func makeVideoCallParticipantModifier(
        options: VideoCallParticipantModifierOptions
    ) -> some ViewModifier {
        VideoCallParticipantModifier(
            participant: options.participant,
            call: options.call,
            availableFrame: options.availableFrame,
            ratio: options.ratio,
            showAllInfo: options.showAllInfo
        )
    }

    public func makeCallView(options: CallViewOptions) -> some View {
        CallView(viewFactory: self, viewModel: options.viewModel)
    }
    
    public func makeMinimizedCallView(options: MinimizedCallViewOptions) -> some View {
        MinimizedCallView(viewFactory: self, viewModel: options.viewModel)
    }

    public func makeCallTopView(options: CallTopViewOptions) -> some View {
        CallTopView(viewFactory: self, viewModel: options.viewModel)
    }

    public func makeParticipantsListView(options: ParticipantsListViewOptions) -> some View {
        if #available(iOS 14.0, *) {
            return CallParticipantsInfoView(
                viewFactory: self,
                callViewModel: options.viewModel
            )
        } else {
            return EmptyView()
        }
    }

    public func makeScreenSharingView(options: ScreenSharingViewOptions) -> some View {
        ScreenSharingView(
            viewModel: options.viewModel,
            screenSharing: options.screenSharingSession,
            availableFrame: options.availableFrame,
            viewFactory: self
        )
    }

    public func makeLobbyView(options: LobbyViewOptions) -> some View {
        let viewModel = options.viewModel
        let lobbyInfo = options.lobbyInfo
        let handleJoinCall = {
            if case .lobby = viewModel.callingState {
                viewModel.startCall(
                    callType: lobbyInfo.callType,
                    callId: lobbyInfo.callId,
                    members: lobbyInfo.participants
                )
            }
        }
        let handleCloseLobby = {
            viewModel.setCallingState(.idle)
        }
        if #available(iOS 14.0, *) {
            return LobbyView(
                viewFactory: self,
                callId: lobbyInfo.callId,
                callType: lobbyInfo.callType,
                callSettings: options.callSettings,
                onJoinCallTap: handleJoinCall,
                onCloseLobby: handleCloseLobby
            )
        } else {
            return LobbyView_iOS13(
                viewFactory: self,
                callViewModel: viewModel,
                callId: lobbyInfo.callId,
                callType: lobbyInfo.callType,
                callSettings: options.callSettings,
                onJoinCallTap: handleJoinCall,
                onCloseLobby: handleCloseLobby
            )
        }
    }

    public func makeReconnectionView(options: ReconnectionViewOptions) -> some View {
        ReconnectionView(viewModel: options.viewModel, viewFactory: self)
    }

    public func makeLocalParticipantViewModifier(
        options: LocalParticipantViewModifierOptions
    ) -> some ViewModifier {
        if #available(iOS 14.0, *) {
            return LocalParticipantViewModifier(
                localParticipant: options.localParticipant,
                call: options.call,
                callSettings: options.callSettings,
                showAllInfo: true
            )
        } else {
            return LocalParticipantViewModifier_iOS13(
                localParticipant: options.localParticipant,
                call: options.call,
                callSettings: options.callSettings,
                showAllInfo: true
            )
        }
    }

    public func makeUserAvatar(options: UserAvatarViewOptions) -> some View {
        UserAvatar(
            imageURL: options.user.imageURL,
            size: options.size,
            failbackProvider: options.failbackProvider
        )
    }

    public func makePermissionsPromptView(options: PermissionsPromptViewOptions) -> some View {
        PermissionsPromptView(call: options.call)
    }
}

public final class DefaultViewFactory: ViewFactory, @unchecked Sendable {

    private nonisolated init() { /* Private init. */ }

    public nonisolated static let shared = DefaultViewFactory()
}
