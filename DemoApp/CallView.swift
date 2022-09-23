//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct CallView: View {
    
    @StateObject var viewModel: CallViewModel
    
    init(callId: String? = nil) {
        _viewModel = StateObject(wrappedValue: CallViewModel())
        if let callId = callId, viewModel.callingState == .idle {
            viewModel.joinCall(callId: callId)
        }
    }
        
    var body: some View {
        ZStack {
            if viewModel.callingState == .outgoing {
                OutgoingCallView(viewModel: viewModel)
            } else if viewModel.callingState == .inCall {
                if viewModel.participants.count > 0 {
                    RoomView(
                        viewFactory: DefaultViewFactory.shared, viewModel: viewModel
                    )
                } else {
                    ZStack {
                        LocalVideoView(callSettings: viewModel.callSettings) { view in
                            if let track = viewModel.localParticipant?.track {
                                view.add(track: track)
                            } else {
                                viewModel.renderLocalVideo(renderer: view)
                            }
                        }
                        VStack {
                            Spacer()
                            CallControlsView(viewModel: viewModel)
                        }
                    }
                }
            } else if case let .incoming(callInfo) = viewModel.callingState {
                IncomingCallView(callInfo: callInfo, onCallAccepted: { callId in
                    viewModel.joinCall(callId: callId)
                }, onCallRejected: { callId in
                    viewModel.callingState = .idle
                })
            }
            else if viewModel.callingState == .idle {
                HomeView(viewModel: viewModel)
            }
        }
    }
}
