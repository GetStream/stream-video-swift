//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct OutgoingCallView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewModel: CallViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if viewModel.participants.count > 1 {
                CallingGroupView(
                    participants: viewModel.participants
                )
            } else {
                CallingParticipantView(
                    participant: viewModel.participants.first
                )
            }
            
            CallingParticipantsView(
                participants: viewModel.participants
            )
            .padding()
            
            Text(L10n.Call.Outgoing.title)
                .applyCallingStyle()

            Spacer()
                   
            CallControlsView(viewModel: viewModel)
        }
        .background(
            Image("incomingCallBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
        )
    }
}
