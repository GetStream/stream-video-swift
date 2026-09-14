//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
public protocol ViewFactory: AnyObject {

    associatedtype CallControlsViewType: View = CallControlsView
    /// Creates the call controls view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the call controls slot.
    func makeCallControlsView(viewModel: CallViewModel) -> CallControlsViewType

    associatedtype OutgoingCallViewType: View
    /// Creates the outgoing call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the outgoing call slot.
    func makeOutgoingCallView(viewModel: CallViewModel) -> OutgoingCallViewType

    associatedtype JoiningCallViewType: View
    /// Creates the joining call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the joining call slot.
    func makeJoiningCallView(viewModel: CallViewModel) -> JoiningCallViewType

    associatedtype IncomingCallViewType: View
    /// Creates the incoming call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the incoming call slot.
    func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> IncomingCallViewType

    associatedtype WaitingLocalUserViewType: View
    /// Creates the waiting local user view, shown when the local participant is the only one on the call.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the waiting local user view.
    func makeWaitingLocalUserView(viewModel: CallViewModel) -> WaitingLocalUserViewType

    associatedtype ParticipantsViewType: View = VideoParticipantsView<Self>
    /// Creates the video participants view, shown during a call.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    ///  - availableFrame: the frame available for rendering.
    ///  - onChangeTrackVisibility: called when a track changes its visibility.
    /// - Returns: view shown in the video participants slot.
    func makeVideoParticipantsView(
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) -> ParticipantsViewType

    associatedtype ParticipantViewType: View = VideoCallParticipantView<Self>
    /// Creates a view for a video call participant with the specified parameters.
    /// - Parameters:
    ///  - participant: The participant to display.
    ///  - id: id of the participant.
    ///  - availableFrame: The available frame for the participant's video view.
    ///  - contentMode: The content mode for the participant's video view.
    ///  - customData: Any custom data passed to the view.
    ///  - onViewUpdate: A closure to be called whenever the participant's video view is updated.
    /// - Returns: A view for the specified video call participant.
    func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        call: Call?
    ) -> ParticipantViewType

    associatedtype ParticipantViewModifierType: ViewModifier = VideoCallParticipantModifier
    /// Creates a view modifier that can be used to modify the appearance of the video call participant view.
    /// - Parameters:
    ///  - participant: The participant to modify.
    ///  - participantCount: The total number of participants in the call.
    ///  - pinnedParticipant: A binding to the participant that is currently pinned in the call.
    ///  - availableFrame: The available frame for the participant's video.
    ///  - ratio: The aspect ratio of the participant's video.
    /// - Returns: A view modifier that modifies the appearance of the video call participant.
    func makeVideoCallParticipantModifier(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool
    ) -> ParticipantViewModifierType

    associatedtype CallViewType: View = CallView<Self>
    /// Creates the call view, shown when a call is in progress.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the call view slot.
    func makeCallView(viewModel: CallViewModel) -> CallViewType
    
    associatedtype MinimizedCallViewType: View = MinimizedCallView<Self>
    /// Creates the minimized call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the minimized call view slot.
    func makeMinimizedCallView(viewModel: CallViewModel) -> MinimizedCallViewType

    associatedtype CallTopViewType: View = CallTopView<Self>
    /// Creates a view displayed at the top of the call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in thetop  call view slot.
    func makeCallTopView(viewModel: CallViewModel) -> CallTopViewType

    associatedtype CallParticipantsListViewType: View
    /// Creates a view that shows a list of the participants in the call.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    /// - Returns: view shown in the participants list slot.
    func makeParticipantsListView(
        viewModel: CallViewModel
    ) -> CallParticipantsListViewType

    associatedtype ScreenSharingViewType: View
    /// Creates a view shown when there's screen sharing session.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    ///  - screensharingSession: The current screensharing session.
    ///  - availableFrame: The frame available to display the view.
    /// - Returns: view shown in the screensharing slot.
    func makeScreenSharingView(
        viewModel: CallViewModel,
        screensharingSession: ScreenSharingSession,
        availableFrame: CGRect
    ) -> ScreenSharingViewType

    associatedtype LobbyViewType: View
    /// Creates the view that's displayed before the user joins the call.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    ///  - lobbyInfo: The waiting room info.
    ///  - callSettings: The call settings.
    /// - Returns: view shown in the pre-joining slot.
    func makeLobbyView(
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) -> LobbyViewType

    associatedtype ReconnectionViewType: View
    /// Creates the view shown when the call is reconnecting.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    /// - Returns: view shown in the reconnection slot.
    func makeReconnectionView(viewModel: CallViewModel) -> ReconnectionViewType

    associatedtype LocalParticipantViewModifierType: ViewModifier
    /// Creates a view modifier for the local participant view.
    /// - Parameters:
    ///   - localParticipant: The local participant.
    ///   - callSettings: The call settings.
    ///   - call: The current call.
    /// - Returns: A view modifier for the local participant view.
    func makeLocalParticipantViewModifier(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>,
        call: Call?
    ) -> LocalParticipantViewModifierType

    associatedtype UserAvatarViewType: View
    /// Creates a user avatar view.
    /// - Parameters:
    ///   - user: The user for whom the avatar is created.
    ///   - options: The options for the avatar view.
    /// - Returns: A view representing the user's avatar.
    func makeUserAvatar(
        _ user: User,
        with options: UserAvatarViewOptions
    ) -> UserAvatarViewType

    associatedtype PermissionsPromptViewType: View
    /// Creates a promptView that asks the user to accept missing permissions.
    /// - Parameters:
    ///   - call: The current call.
    /// - Returns: A view representing the user's avatar.
    func makePermissionsPromptView(
        call: Call?
    ) -> PermissionsPromptViewType
}

extension ViewFactory {

    public func makeCallControlsView(viewModel: CallViewModel) -> some View {
        CallControlsView(viewModel: viewModel)
    }

    public func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
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
            callTopView: makeCallTopView(viewModel: viewModel),
            callControls: makeCallControlsView(viewModel: viewModel)
        )
    }

    public func makeJoiningCallView(viewModel: CallViewModel) -> some View {
        JoiningCallView(
            viewFactory: self,
            callTopView: makeCallTopView(viewModel: viewModel),
            callControls: makeCallControlsView(viewModel: viewModel)
        )
    }

    public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
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

    public func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        WaitingLocalUserView(viewModel: viewModel, viewFactory: self)
    }

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

    public func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        call: Call?
    ) -> some View {
        VideoCallParticipantView(
            viewFactory: self,
            participant: participant,
            id: id,
            availableFrame: availableFrame,
            contentMode: contentMode,
            customData: customData,
            call: call
        )
    }

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

    public func makeCallView(viewModel: CallViewModel) -> some View {
        CallView(viewFactory: self, viewModel: viewModel)
    }
    
    public func makeMinimizedCallView(viewModel: CallViewModel) -> some View {
        MinimizedCallView(viewFactory: self, viewModel: viewModel)
    }

    public func makeCallTopView(viewModel: CallViewModel) -> some View {
        CallTopView(viewFactory: self, viewModel: viewModel)
    }

    public func makeParticipantsListView(
        viewModel: CallViewModel
    ) -> some View {
        if #available(iOS 14.0, *) {
            return CallParticipantsInfoView(
                viewFactory: self,
                callViewModel: viewModel
            )
        } else {
            return EmptyView()
        }
    }

    public func makeScreenSharingView(
        viewModel: CallViewModel,
        screensharingSession: ScreenSharingSession,
        availableFrame: CGRect
    ) -> some View {
        ScreenSharingView(
            viewModel: viewModel,
            screenSharing: screensharingSession,
            availableFrame: availableFrame,
            viewFactory: self
        )
    }

    public func makeLobbyView(
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) -> some View {
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
                callSettings: callSettings,
                onJoinCallTap: handleJoinCall,
                onCloseLobby: handleCloseLobby
            )
        } else {
            return LobbyView_iOS13(
                viewFactory: self,
                callViewModel: viewModel,
                callId: lobbyInfo.callId,
                callType: lobbyInfo.callType,
                callSettings: callSettings,
                onJoinCallTap: handleJoinCall,
                onCloseLobby: handleCloseLobby
            )
        }
    }

    public func makeReconnectionView(viewModel: CallViewModel) -> some View {
        ReconnectionView(viewModel: viewModel, viewFactory: self)
    }

    public func makeLocalParticipantViewModifier(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>,
        call: Call?
    ) -> some ViewModifier {
        if #available(iOS 14.0, *) {
            return LocalParticipantViewModifier(
                localParticipant: localParticipant,
                call: call,
                callSettings: callSettings,
                showAllInfo: true
            )
        } else {
            return LocalParticipantViewModifier_iOS13(
                localParticipant: localParticipant,
                call: call,
                callSettings: callSettings,
                showAllInfo: true
            )
        }
    }

    public func makeUserAvatar(
        _ user: User,
        with options: UserAvatarViewOptions
    ) -> some View {
        UserAvatar(
            imageURL: user.imageURL,
            size: options.size,
            failbackProvider: options.failbackProvider
        )
    }

    public func makePermissionsPromptView(
        call: Call?
    ) -> some View {
        PermissionsPromptView(call: call)
    }
}

public final class DefaultViewFactory: ViewFactory, @unchecked Sendable {

    private nonisolated init() { /* Private init. */ }

    public nonisolated static let shared = DefaultViewFactory()
}
