//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
public protocol ViewFactory: AnyObject {
    
    associatedtype CallControlsViewType: View = CallControlsView
    func makeCallControlsView(viewModel: CallViewModel) -> CallControlsViewType
    
    associatedtype OutgoingCallViewType: View = OutgoingCallView
    func makeOutgoingCallView(viewModel: CallViewModel) -> OutgoingCallViewType
    
    associatedtype IncomingCallViewType: View = IncomingCallView
    func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> IncomingCallViewType
    
    associatedtype ParticipantsViewType: View = VideoParticipantsView
    func makeVideoParticipantsView(
        participants: [CallParticipant],
        availableSize: CGSize,
        onViewRendering: @escaping (StreamMTLVideoView, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> ParticipantsViewType
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
        onViewRendering: @escaping (StreamMTLVideoView, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) -> some View {
        VideoParticipantsView(
            participants: participants,
            availableSize: availableSize,
            onViewRendering: onViewRendering,
            onChangeTrackVisibility: onChangeTrackVisibility
        )
    }
}

public class DefaultViewFactory: ViewFactory {
    
    private init() { /* Private init. */ }
    
    public static let shared = DefaultViewFactory()
}
