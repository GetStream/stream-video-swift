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
}

extension ViewFactory {
    
    public func makeCallControlsView(viewModel: CallViewModel) -> some View {
        CallControlsView(viewModel: viewModel)
    }
    
    public func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
        OutgoingCallView(viewModel: viewModel)
    }
    
    public func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
        IncomingCallView(callInfo: callInfo, onCallAccepted: { callId in
            viewModel.joinCall(callId: callId)
        }, onCallRejected: { _ in
            viewModel.callingState = .idle
        })
    }
}

public class DefaultViewFactory: ViewFactory {
    
    private init() { /* Private init. */ }
    
    public static let shared = DefaultViewFactory()
}
