//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct CallView: View {
    
    @StateObject var viewModel: CallViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: CallViewModel())
    }
        
    var body: some View {
        ZStack {
            if viewModel.calling {
                OutgoingCallView(viewModel: viewModel)
            } else if viewModel.shouldShowRoomView {
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
            } else {
                HomeView(viewModel: viewModel)
            }
        }
    }
}
