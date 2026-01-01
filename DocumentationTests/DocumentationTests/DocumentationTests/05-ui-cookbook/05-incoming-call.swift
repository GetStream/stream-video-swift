//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    
    container {
        struct CustomIncomingCallView: View {

            @Injected(\.colors) var colors

            @ObservedObject var callViewModel: CallViewModel
            @StateObject var viewModel: IncomingViewModel

            init(
                callInfo: IncomingCall,
                callViewModel: CallViewModel
            ) {
                self.callViewModel = callViewModel
                _viewModel = StateObject(
                    wrappedValue: IncomingViewModel(callInfo: callInfo)
                )
            }

            var body: some View {
                VStack {
                    Spacer()
                    Text("Incoming call")
                        .foregroundColor(Color(colors.textLowEmphasis))
                        .padding()

                    StreamLazyImage(imageURL: callInfo.caller.imageURL)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()

                    Text(callInfo.caller.name)
                        .font(.title)
                        .foregroundColor(Color(colors.textLowEmphasis))
                        .padding()

                    Spacer()

                    HStack(spacing: 16) {
                        Spacer()

                        Button {
                            callViewModel.rejectCall(callType: callInfo.type, callId: callInfo.id)
                        } label: {
                            Image(systemName: "phone.down.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        .padding(.all, 8)

                        Button {
                            callViewModel.acceptCall(callType: callInfo.type, callId: callInfo.id)
                        } label: {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        .padding(.all, 8)

                        Spacer()
                    }
                    .padding()
                }
                .background(Color.white.edgesIgnoringSafeArea(.all))
            }

            var callInfo: IncomingCall {
                viewModel.callInfo
            }
        }

        class CustomViewFactory: ViewFactory {

            func makeIncomingCallView(viewModel: CallViewModel, callInfo: IncomingCall) -> some View {
                CustomIncomingCallView(callInfo: callInfo, callViewModel: viewModel)
            }
        }
    }
}
