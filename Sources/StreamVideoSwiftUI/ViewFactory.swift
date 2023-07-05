//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    ///  - availableSize: the size available for rendering.
    ///  - onViewRendering: called when the video view is rendered.
    ///  - onChangeTrackVisibility: called when a track changes its visibility.
    /// - Returns: view shown in the video participants slot.
    func makeVideoParticipantsView(
        viewModel: CallViewModel,
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> ParticipantsViewType
    
    associatedtype ParticipantViewType: View = VideoCallParticipantView
    /// Creates a view for a video call participant with the specified parameters.
    /// - Parameters:
    ///  - participant: The participant to display.
    ///  - id: id of the participant.
    ///  - availableSize: The available size for the participant's video view.
    ///  - contentMode: The content mode for the participant's video view.
    ///  - customData: Any custom data passed to the view.
    ///  - onViewUpdate: A closure to be called whenever the participant's video view is updated.
    /// - Returns: A view for the specified video call participant.
    func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) -> ParticipantViewType
    
    associatedtype ParticipantViewModifierType: ViewModifier = VideoCallParticipantModifier
    /// Creates a view modifier that can be used to modify the appearance of the video call participant view.
    /// - Parameters:
    ///  - participant: The participant to modify.
    ///  - participantCount: The total number of participants in the call.
    ///  - pinnedParticipant: A binding to the participant that is currently pinned in the call.
    ///  - availableSize: The available size for the participant's video.
    ///  - ratio: The aspect ratio of the participant's video.
    /// - Returns: A view modifier that modifies the appearance of the video call participant.
    func makeVideoCallParticipantModifier(
        participant: CallParticipant,
        participantCount: Int,
        pinnedParticipant: Binding<CallParticipant?>,
        availableSize: CGSize,
        ratio: CGFloat,
        showAllInfo: Bool
    ) -> ParticipantViewModifierType
    
    associatedtype CallViewType: View = CallView<Self>
    /// Creates the call view, shown when a call is in progress.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the call view slot.
    func makeCallView(viewModel: CallViewModel) -> CallViewType
    
    associatedtype CallTopViewType: View = CallTopView
    /// Creates a view displayed at the top of the call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in thetop  call view slot.
    func makeCallTopView(viewModel: CallViewModel) -> CallTopViewType
        
    associatedtype CallParticipantsListViewType: View
    /// Creates a view that shows a list of the participants in the call.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    ///  - availableSize: The size available to display the view.
    /// - Returns: view shown in the participants list slot.
    func makeParticipantsListView(
        viewModel: CallViewModel,
        availableSize: CGSize
    ) -> CallParticipantsListViewType
    
    associatedtype ScreenSharingViewType: View
    /// Creates a view shown when there's screen sharing session.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    ///  - screensharingSession: The current screensharing session.
    ///  - availableSize: The size available to display the view.
    /// - Returns: view shown in the screensharing slot.
    func makeScreenSharingView(
        viewModel: CallViewModel,
        screensharingSession: ScreenSharingSession,
        availableSize: CGSize
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

    associatedtype LocalParticipantViewModifierType = ViewModifier
    func makeLocalParticipantViewModifier(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>
    ) -> LocalParticipantViewModifierType
}

extension ViewFactory {
    
    public func makeCallControlsView(viewModel: CallViewModel) -> some View {
        CallControlsView(viewModel: viewModel)
    }
    
    public func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
        OutgoingCallView(
            outgoingCallMembers: viewModel.outgoingCallMembers.map(\.toMember),
            callControls: makeCallControlsView(viewModel: viewModel)
        )
    }
    
    public func makeJoiningCallView(viewModel: CallViewModel) -> some View {
        JoiningCallView(
            callControls: makeCallControlsView(viewModel: viewModel)
        )
    }
    
    public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
        if #available(iOS 14.0, *) {
            return IncomingCallView(callInfo: callInfo, onCallAccepted: { _ in
                viewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
            }, onCallRejected: { _ in
                viewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
            })
        } else {
            return IncomingCallView_iOS13(callInfo: callInfo, onCallAccepted: { _ in
                viewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
            }, onCallRejected: { _ in
                viewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
            })
        }
    }
    
    public func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        WaitingLocalUserView(viewModel: viewModel, viewFactory: self)
    }
    
    public func makeVideoParticipantsView(
        viewModel: CallViewModel,
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> some View {
        VideoParticipantsView(
            viewFactory: self,
            viewModel: viewModel,
            availableSize: availableSize,
            onViewRendering: onViewRendering,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }
    
    public func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) -> some View {
        VideoCallParticipantView(
            participant: participant,
            id: id,
            availableSize: availableSize,
            contentMode: contentMode,
            customData: customData,
            onViewUpdate: onViewUpdate
        )
    }
    
    public func makeVideoCallParticipantModifier(
        participant: CallParticipant,
        participantCount: Int,
        pinnedParticipant: Binding<CallParticipant?>,
        availableSize: CGSize,
        ratio: CGFloat,
        showAllInfo: Bool
    ) -> some ViewModifier {
        VideoCallParticipantModifier(
            participant: participant,
            pinnedParticipant: pinnedParticipant,
            participantCount: participantCount,
            availableSize: availableSize,
            ratio: ratio,
            showAllInfo: showAllInfo
        )
    }
    
    public func makeCallView(viewModel: CallViewModel) -> some View {
        CallView(viewFactory: self, viewModel: viewModel)
    }
    
    public func makeCallTopView(viewModel: CallViewModel) -> some View {
        CallTopView(viewModel: viewModel)
    }
    
    public func makeParticipantsListView(
        viewModel: CallViewModel,
        availableSize: CGSize
    ) -> some View {
        if #available(iOS 14.0, *) {
            return CallParticipantsInfoView(callViewModel: viewModel, availableSize: availableSize)
        } else {
            return EmptyView()
        }
    }
    
    public func makeScreenSharingView(
        viewModel: CallViewModel,
        screensharingSession: ScreenSharingSession,
        availableSize: CGSize
    ) -> some View {
        ScreenSharingView(
            viewModel: viewModel,
            screenSharing: screensharingSession,
            availableSize: availableSize
        )
    }
    
    public func makeLobbyView(
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) -> some View {
        let handleJoinCall = {
            if case .lobby(_) = viewModel.callingState {
                viewModel.startCall(
                    callType: lobbyInfo.callType,
                    callId: lobbyInfo.callId,
                    members: lobbyInfo.participants
                )
            }
        }
        let handleCloseLobby = {
            viewModel.callingState = .idle
        }
        if #available(iOS 14.0, *) {
            return LobbyView(
                callId: lobbyInfo.callId,
                callType: lobbyInfo.callType,
                callParticipants: lobbyInfo.participants.map(\.toMember),
                callSettings: callSettings,
                onJoinCallTap: handleJoinCall,
                onCloseLobby: handleCloseLobby
            )
        } else {
            return LobbyView_iOS13(
                callViewModel: viewModel,
                callId: lobbyInfo.callId,
                callType: lobbyInfo.callType,
                callParticipants: lobbyInfo.participants.map(\.toMember),
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
        callSettings: Binding<CallSettings>
    ) -> some ViewModifier {
        if #available(iOS 14.0, *) {
            return LocalParticipantViewModifier(
                localParticipant: localParticipant,
                callSettings: callSettings
            )
        } else {
            return LocalParticipantViewModifier_iOS13(
                localParticipant: localParticipant,
                callSettings: callSettings
            )
        }
    }
}

public class DefaultViewFactory: ViewFactory {
    
    private init() { /* Private init. */ }
    
    public static let shared = DefaultViewFactory()
}
