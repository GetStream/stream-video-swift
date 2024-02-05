//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Intents
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DetailedCallingView: View {
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject private var appState = AppState.shared

    private let imageSize: CGFloat = 32

    private var participants: [User] {
        var participants = AppState.shared.users
        participants.removeAll { userInfo in
            userInfo.id == streamVideo.user.id
        }
        return participants
    }

    private var makeCallEnabled: Bool {
        text.isEmpty || participants.isEmpty
    }

    private var members: [MemberRequest] {
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

    @State private var text = ""
    @State private var callAction = CallAction.startCall
    @State private var callFlow: CallFlow = .joinImmediately

    @State var selectedParticipants = [User]()
    @State var incomingCallInfo: IncomingCall?
    @State var logoutAlertShown = false

    private var isActionDisabled: Bool {
        guard AppEnvironment.configuration != .test else {
            return false
        }
        return appState.loading || text.isEmpty
    }

    var body: some View {
        VStack {
            DemoCallingTopView(callViewModel: viewModel)
                .padding(.horizontal)
                .padding(.top)

            HStack {
                TextField("Call ID", text: $text)
                    .foregroundColor(appearance.colors.text)
                    .padding(.all, 12)
                    .accessibilityIdentifier("callId")

                Button {
                    text = String(
                        String
                            .unique
                            .replacingOccurrences(of: "-", with: "")
                            .prefix(10)
                    )
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.init(appearance.colors.textLowEmphasis))
                }
                .padding(.trailing)
            }
            .background(Color(appearance.colors.background))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))
            .padding(.bottom, 4)
            .padding(.horizontal)

            Picker("Call action", selection: $callAction) {
                Text(CallAction.startCall.rawValue).tag(CallAction.startCall)
                Text(CallAction.joinCall.rawValue).tag(CallAction.joinCall)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if callAction == .startCall {
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
                            Label {
                                Text(participant.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } icon: {
                                UserAvatar(imageURL: participant.imageURL, size: imageSize)
                            }

                            if selectedParticipants.contains(participant) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(4)
                    }
                    .listRowBackground(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .listStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .padding(.horizontal)
            } else {
                Spacer()
            }

            Button {
                resignFirstResponder()
                if callAction == .joinCall {
                    viewModel.joinCall(callType: .default, callId: text)
                } else {
                    if callFlow == .lobby {
                        viewModel.enterLobby(
                            callType: .default,
                            callId: text,
                            members: members
                        )
                    } else {
                        viewModel.startCall(
                            callType: .default,
                            callId: text,
                            members: members,
                            ring: callFlow == .ringEvents
                        )
                    }
                }
            } label: {
                CallButtonView(
                    title: callAction == .joinCall ? "Join Call" : "Start Call",
                    isDisabled: isActionDisabled
                )
            }
            .padding(.bottom)
            .padding(.horizontal)
            .disabled(isActionDisabled)
            .accessibilityIdentifier(callAction == .joinCall ? "joinCall" : "startCall")
        }
        .alignedToReadableContentGuide()
        .background(appearance.colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .onChange(of: appState.deeplinkInfo) { deeplinkInfo in
            self.text = deeplinkInfo.callId
            joinCallIfNeeded(with: deeplinkInfo.callId, callType: deeplinkInfo.callType)
        }
        .onChange(of: viewModel.callingState) { callingState in
            switch callingState {
            case .inCall:
                appState.deeplinkInfo = .empty
            default:
                break
            }
        }
        .onAppear {
            CallService.shared.registerForIncomingCalls()
            self.text = text
            joinCallIfNeeded(with: text)
        }
        .onReceive(appState.$activeCall) { call in
            viewModel.setActiveCall(call)
        }
        .onChange(of: viewModel.call?.callId, perform: { [callId = viewModel.call?.callId] newValue in
            if newValue == nil, callId != nil, !appState.activeAnonymousCallId.isEmpty {
                appState.activeAnonymousCallId = ""
                appState.dispatchLogout()
            }
        })
        .onReceive(appState.$activeAnonymousCallId) { callId in
            guard !callId.isEmpty else { return }
            self.text = callId
            viewModel.joinCall(callType: .default, callId: callId)
        }
    }

    private func joinCallIfNeeded(
        with callId: String,
        callType: String = .default
    ) {
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
