//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Intents
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DetailedCallingView: View {
    @ObservedObject var viewModel: CallViewModel

    @Injected(\.streamVideo) var streamVideo

    private let imageSize: CGFloat = 32

    @State private var callId = ""

    @State private var callAction = CallAction.startCall

    @State private var callFlow: CallFlow = .joinImmediately

    var participants: [User] {
        var participants = AppState.shared.users
        participants.removeAll { userInfo in
            userInfo.id == streamVideo.user.id
        }
        return participants
    }

    @State var selectedParticipants = [User]()
    @State var incomingCallInfo: IncomingCall?
    @State var logoutAlertShown = false

    @ObservedObject var appState = AppState.shared

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    HStack {
                        Button {
                            logoutAlertShown = !AppEnvironment.configuration.isRelease
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

                    HStack {
                        Spacer()
                        ZStack {
                            if appState.loading {
                                ProgressView()
                            } else {
                                NavigationLink {
                                    CallsView()
                                } label: {
                                    Text("Calls")
                                }

                            }
                        }
                        .padding()
                    }
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
                        resignFirstResponder()
                        viewModel.joinCall(callType: .default, callId: callId)
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
            .alignedToReadableContentGuide()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear() {
            CallService.shared.registerForIncomingCalls()
        }
        .alert(isPresented: $logoutAlertShown) {
            Alert(
                title: Text("Sign out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign out")) {
                    withAnimation {
                        AppState.shared.dispatchLogout()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .background(
            viewModel.callingState == .inCall && !viewModel.isMinimized ? Color.black.edgesIgnoringSafeArea(.all) : nil
        )
        .onChange(of: viewModel.call?.callId, perform: { [callId = viewModel.call?.callId] newValue in
            if newValue == nil, callId != nil, !appState.activeAnonymousCallId.isEmpty {
                appState.activeAnonymousCallId = ""
                appState.dispatchLogout()
            }
        })
        .onReceive(appState.$activeCall) { call in
            viewModel.setActiveCall(call)
        }
        .onReceive(appState.$activeAnonymousCallId) { callId in
            guard !callId.isEmpty else { return }
            self.callId = callId
            viewModel.joinCall(callType: .default, callId: callId)
        }
        .onReceive(appState.$deeplinkInfo) { deeplinkInfo in
            self.callId = deeplinkInfo.callId
            joinCallIfNeeded(with: deeplinkInfo.callId, callType: deeplinkInfo.callType)
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
            .accessibility(identifier: "participantList")

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
                    viewModel.enterLobby(callType: .default, callId: callId, members: members)
                } else {
                    viewModel.startCall(
                        callType: .default,
                        callId: callId,
                        members: members,
                        ring: callFlow == .ringEvents
                    )
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

    var members: [MemberRequest] {
        var members: [MemberRequest] = selectedParticipants.map {
            MemberRequest(custom: $0.customData, role: $0.role, userId: $0.id)
        }
        if !selectedParticipants.contains(streamVideo.user) {
            let currentUser = streamVideo.user
            let member = MemberRequest(
                custom: currentUser.customData,
                role: currentUser.role,
                userId: currentUser.id
            )
            members.append(member)
        }
        return members
    }

    private func joinCallIfNeeded(with callId: String, callType: String = .default) {
        guard !callId.isEmpty, viewModel.callingState == .idle else {
            return
        }

        Task {
            try await streamVideo.connect()
            await MainActor.run {
                viewModel.joinCall(callType: callType, callId: callId)
            }
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
