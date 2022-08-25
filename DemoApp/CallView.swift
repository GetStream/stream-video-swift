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
                    RemoteParticipantsView(participants: viewModel.participants)
                } else {
                    LocalVideoView()
                }
            } else {
                HomeView(viewModel: viewModel)
            }
        }
    }
}
