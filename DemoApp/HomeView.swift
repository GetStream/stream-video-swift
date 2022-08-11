//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.streamVideo) var streamVideo
    
    @State private var callId = ""
    
    @State private var callAction = CallAction.startCall
    
    var participants: [UserCredentials] {
        var participants = UserCredentials.builtInUsers
        participants.removeAll { userCredentials in
            userCredentials.id == streamVideo.userInfo.id
        }
        return participants
    }
    
    @State var selectedParticipants = [String]()
    
    @State var incomingCallInfo: IncomingCall?
    
    var body: some View {
        VStack {
            Text("Call details")
                .font(.title)
                .padding()
            
            Picker("Call action", selection: $callAction) {
                Text(CallAction.startCall.rawValue).tag(CallAction.startCall)
                Text(CallAction.joinCall.rawValue).tag(CallAction.joinCall)
            }
            .pickerStyle(.segmented)
            
            TextField("Insert a call id", text: $callId)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            if callAction == .startCall {
                startCallView
                    .transition(.opacity)
            } else {
                Button {
                    viewModel.joinCall(callId: callId)
                } label: {
                    Text("Join a call")
                        .padding()
                }
                .foregroundColor(Color.white)
                .background(makeCallEnabled ? Color.gray : Color.blue)
                .disabled(makeCallEnabled)
                .cornerRadius(16)
                .transition(.opacity)
            }

            Spacer()
        }
        .onAppear() {
            Task {
                for await incomingCall in streamVideo.incomingCalls() {
                    self.incomingCallInfo = incomingCall
                }
            }
            CallService.shared.registerForIncomingCalls()
        }
        .fullScreenCover(item: $incomingCallInfo) { callInfo in
            IncomingCallView(callInfo: callInfo, onCallAccepted: { callId in
                //TODO: wait before dismissing the screen
                viewModel.joinCall(callId: callId)
                incomingCallInfo = nil
            }, onCallRejected: { callId in
                incomingCallInfo = nil
            })
        }
    }
    
    private var makeCallEnabled: Bool {
        callId.isEmpty || participants.isEmpty
    }
    
    var startCallView: some View {
        Group {
            HStack {
                Text("Select participants")
                    .font(.title2)
                Spacer()
            }
            .padding(.horizontal)
            
            List(participants) { participant in
                Button {
                    if selectedParticipants.contains(participant.id) {
                        selectedParticipants.removeAll { id in
                            id == participant.id
                        }
                    } else {
                        selectedParticipants.append(participant.id)
                    }
                } label: {
                    HStack {
                        Text(participant.userInfo.name ?? participant.userInfo.id)
                        Spacer()
                        if selectedParticipants.contains(participant.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.all, 8)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height / 4)
            .listStyle(PlainListStyle())
                        
            Button {
                viewModel.startCall(callId: callId, participantIds: selectedParticipants)
            } label: {
                Text("Start a call")
                    .padding()
            }
            .foregroundColor(Color.white)
            .background(makeCallEnabled ? Color.gray : Color.blue)
            .disabled(makeCallEnabled)
            .cornerRadius(16)

        }
    }
    
}

enum CallAction: String {
    case startCall = "Start a call"
    case joinCall = "Join a call"
}
