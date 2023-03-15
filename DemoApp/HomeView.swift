//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Intents
import NukeUI
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.streamVideo) var streamVideo
    
    private let imageSize: CGFloat = 32
        
    @State private var callId = ""
    
    @State private var callAction = CallAction.startCall
    
    @State private var callFlow: CallFlow = .joinImmediately
    
    var participants: [User] {
        var participants = User.builtInUsers
        participants.removeAll { userInfo in
            userInfo.id == streamVideo.user.id
        }
        return participants
    }
    
    @State var selectedParticipants = [User]()
    @State var incomingCallInfo: IncomingCall?
    @State var logoutAlertShown = false
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Button {
                        logoutAlertShown = true
                    } label: {
                        UserAvatar(imageURL: streamVideo.user.imageURL, size: imageSize)
                            .accessibilityIdentifier("userAvatar")
                    }
                    .padding()

                    Spacer()
                }
                Text("Call details")
                    .font(.title)
                    .padding()
            }
            
            Picker("Call action", selection: $callAction) {
                Text(CallAction.startCall.rawValue).tag(CallAction.startCall)
                Text(CallAction.joinCall.rawValue).tag(CallAction.joinCall)
            }
            .pickerStyle(.segmented)
            
            TextField("Insert a call id", text: $callId)
                .textFieldStyle(.roundedBorder)
                .padding()
                .accessibilityIdentifier("callId")
            
            if callAction == .startCall {
                startCallView
                    .transition(.opacity)
            } else {
                Button {
                    viewModel.joinCall(callId: callId, type: "default")
                } label: {
                    Text("Join a call")
                        .padding()
                        .accessibilityIdentifier("joinCall")
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
            CallService.shared.registerForIncomingCalls()
        }
        .alert(isPresented: $logoutAlertShown) {
            Alert(
                title: Text("Sign out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign out")) {
                    withAnimation {
                        if let userToken = UnsecureUserRepository.shared.currentVoipPushToken() {
                            let controller = streamVideo.makeVoipNotificationsController()
                            controller.removeDevice(with: userToken)
                        }
                        UnsecureUserRepository.shared.removeCurrentUser()
                        Task {
                            await streamVideo.disconnect()
                            AppState.shared.streamVideo = nil
                            AppState.shared.userState = .notLoggedIn
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .background(
            viewModel.callingState == .inCall && !viewModel.isMinimized ? Color.black.edgesIgnoringSafeArea(.all) : nil
        )        
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
                    if selectedParticipants.contains(participant) {
                        selectedParticipants.removeAll { user in
                            user.id == participant.id
                        }
                    } else {
                        selectedParticipants.append(participant)
                    }
                } label: {
                    HStack {
                        UserAvatar(imageURL: participant.imageURL, size: imageSize)
                        Text(participant.name)
                        Spacer()
                        if selectedParticipants.contains(participant) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.all, 8)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height / 4)
            .listStyle(PlainListStyle())
            
            Picker("Call flow", selection: $callFlow) {
                Text(CallFlow.joinImmediately.rawValue)
                    .tag(CallFlow.joinImmediately)
                    .accessibility(identifier: CallFlow.joinImmediately.rawValue)
                Text(CallFlow.ringEvents.rawValue)
                    .tag(CallFlow.ringEvents)
                    .accessibility(identifier: CallFlow.ringEvents.rawValue)
                Text(CallFlow.lobby.rawValue)
                    .tag(CallFlow.lobby)
                    .accessibility(identifier: CallFlow.lobby.rawValue)
            }
            .pickerStyle(.segmented)
                        
            Button {
                resignFirstResponder()
                if callFlow == .lobby {
                    viewModel.enterLobby(callId: callId, type: "default", participants: selectedParticipants)
                } else {
                    viewModel.startCall(callId: callId, type: "default", participants: selectedParticipants, ring: callFlow == .ringEvents)
                }
            } label: {
                Text("Start a call")
                    .padding()
                    .accessibilityIdentifier("startCall")
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

enum CallFlow: String {
    case ringEvents = "Ring events"
    case lobby = "Lobby"
    case joinImmediately = "Join immediately"
}
