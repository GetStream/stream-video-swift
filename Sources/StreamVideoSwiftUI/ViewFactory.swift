//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    
    associatedtype OutgoingCallViewType: View = OutgoingCallView
    /// Creates the outgoing call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the outgoing call slot.
    func makeOutgoingCallView(viewModel: CallViewModel) -> OutgoingCallViewType
    
    associatedtype IncomingCallViewType: View = IncomingCallView
    /// Creates the incoming call view.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the incoming call slot.
    func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> IncomingCallViewType
    
    associatedtype ParticipantsViewType: View = VideoParticipantsView
    /// Creates the video participants view, shown during a call.
    /// - Parameters:
    ///  - participants: the participants in the call.
    ///  - availableSize: the size available for rendering.
    ///  - onViewRendering: called when the video view is rendered.
    ///  - onChangeTrackVisibility: called when a track changes its visibility.
    /// - Returns: view shown in the video participants slot.
    func makeVideoParticipantsView(
        participants: [CallParticipant],
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> ParticipantsViewType
    
    associatedtype CallViewType: View = CallView<Self>
    /// Creates the call view, shown when a call is in progress.
    /// - Parameter viewModel: The view model used for the call.
    /// - Returns: view shown in the call view slot.
    func makeCallView(viewModel: CallViewModel) -> CallViewType
        
    associatedtype CallParticipantsListViewType: View = CallParticipantsInfoView
    /// Creates a view in the top trailing section of the call view.
    /// - Parameters:
    ///  - viewModel: The view model used for the call.
    ///  - availableSize: The size available to display the view.
    /// - Returns: view shown in the participants list slot.
    func makeTrailingTopView(
        viewModel: CallViewModel,
        availableSize: CGSize
    ) -> CallParticipantsListViewType
}

extension ViewFactory {
    
    public func makeCallControlsView(viewModel: CallViewModel) -> some View {
        CallControlsView(viewModel: viewModel)
    }
    
    public func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
        OutgoingCallView(viewModel: viewModel)
    }
    
    public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
        IncomingCallView(callInfo: callInfo, onCallAccepted: { _ in
            viewModel.acceptCall(callId: callInfo.id, type: callInfo.type)
        }, onCallRejected: { _ in
            viewModel.rejectCall(callId: callInfo.id, type: callInfo.type)
        })
    }
    
    public func makeVideoParticipantsView(
        participants: [CallParticipant],
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> some View {
        VideoParticipantsView(
            participants: participants,
            availableSize: availableSize,
            onViewRendering: onViewRendering,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }
    
    public func makeCallView(viewModel: CallViewModel) -> some View {
        CallView(viewFactory: self, viewModel: viewModel)
    }
    
    public func makeTrailingTopView(
        viewModel: CallViewModel,
        availableSize: CGSize
    ) -> some View {
        CallParticipantsInfoView(viewModel: viewModel, availableSize: availableSize)
    }
}

public class DefaultViewFactory: ViewFactory {
    
    private init() { /* Private init. */ }
    
    public static let shared = DefaultViewFactory()
}
