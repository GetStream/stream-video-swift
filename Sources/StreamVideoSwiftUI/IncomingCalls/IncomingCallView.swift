//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

public struct IncomingCallView: View {
    
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
        VStack {
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
            
            // TODO: include participant names.
            Text("Incoming video call")
                .padding()
                .foregroundColor(.white)
            
            Spacer()
                        
            HStack {
                Button {
                    onCallRejected(viewModel.callInfo.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60)
                        .foregroundColor(.red)
                }
                .padding(.all, 8)

                Button {
                    onCallAccepted(viewModel.callInfo.id)
                } label: {
                    Image(systemName: "phone.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60)
                        .foregroundColor(.green)
                }
                .padding(.all, 8)
            }
        }
        .background(
            Image("incomingCallBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
        )
    }
}
