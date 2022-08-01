//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct IncomingCallView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: CallViewModel
    
    var callInfo: IncomingCall
    
    var body: some View {
        VStack {
            Text("\(callInfo.callerId) is calling you")
                .font(.title)
            
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60)
                        .foregroundColor(.red)
                }
                .padding(.all, 8)

                Button {
                    viewModel.joinCall(callId: callInfo.id)
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
        .overlay(
            viewModel.loading ? ProgressView() : nil
        )
        .onChange(of: viewModel.loading) { newValue in
            if newValue == false {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
