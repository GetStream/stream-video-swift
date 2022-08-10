//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

public struct IncomingCallView: View {
    
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    
    @StateObject var viewModel: IncomingViewModel
            
    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void
    
    public init(
        callInfo: IncomingCall,
        onCallAccepted: @escaping (String) -> Void,
        onCallRejected: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: IncomingViewModel(callInfo: callInfo)
        )
        self.onCallAccepted = onCallAccepted
        self.onCallRejected = onCallRejected
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if viewModel.callParticipants.count > 1 {
                GroupIncomingCallView(
                    participants: viewModel.callParticipants,
                    incomingCall: viewModel.callInfo
                )
            } else {
                DirectIncomingCallView(
                    participant: viewModel.callParticipants.first,
                    incomingCall: viewModel.callInfo
                )
            }
            
            IncomingCallParticipantsView(
                participants: viewModel.callParticipants,
                callInfo: viewModel.callInfo
            )
            .padding()
            
            Text(L10n.Call.Incoming.title)
                .font(fonts.title2)
                .fontWeight(.semibold)
                .foregroundColor(colors.lightGray)

            Spacer()
                        
            HStack {
                Spacing()
                
                Button {
                    onCallRejected(viewModel.callInfo.id)
                } label: {
                    images.hangup
                        .applyCallButtonStyle(
                            color: Color.red,
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, 8)
                
                Spacing(size: 3)

                Button {
                    onCallAccepted(viewModel.callInfo.id)
                } label: {
                    images.acceptCall
                        .applyCallButtonStyle(
                            color: Color.green,
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, 8)
                
                Spacing()
            }
            .padding()
        }
        .background(
            Image("incomingCallBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
        )
    }
}
