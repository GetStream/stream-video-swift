//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallConnectingView: View {
    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    @ObservedObject var viewModel: CallViewModel
    var title: String
    
    public init(viewModel: CallViewModel, title: String) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.title = title
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()
                
                if viewModel.outgoingCallMembers.count > 1 {
                    CallingGroupView(
                        participants: viewModel.outgoingCallMembers
                    )
                } else if viewModel.outgoingCallMembers.count > 0 {
                    AnimatingParticipantView(
                        participant: viewModel.outgoingCallMembers.first
                    )
                }
                
                CallingParticipantsView(
                    participants: viewModel.outgoingCallMembers
                )
                .padding()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(title)
                        .applyCallingStyle()
                    CallingIndicator()
                }
                
                Spacer()
                
                CallControlsView(viewModel: viewModel)
            }
        }
        .background(
            OutgoingCallBackground(viewModel: viewModel)
        )
    }
}
