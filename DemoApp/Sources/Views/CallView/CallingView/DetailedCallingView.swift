//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Intents
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DetailedCallingView: View {
    enum CallAction: String, CaseIterable {
        case startCall = "Start a call"
        case joinCall = "Join a call"
    }

    enum CallFlow: String, CaseIterable {
        case joinImmediately = "Join immediately"
        case ringEvents = "Ring events"
        case lobby = "Lobby"
    }

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject private var appState = AppState.shared

    private let imageSize: CGFloat = 32

    private var participants: [User] {
        AppState.shared.users.filter { $0.id != streamVideo.user.id }
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
    @State private var callAction: CallAction = .startCall
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

    private var isAnonymous: Bool { appState.currentUser == .anonymous }
    private var canStartCall: Bool { appState.currentUser?.type == .regular }

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
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
                    .disabled(isAnonymous)

                if canStartCall {
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
            }
            .background(Color(appearance.colors.background))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))
            .padding(.bottom, 4)
            .padding(.horizontal)

            if canStartCall {
                Picker("Call action", selection: $callAction) {
                    ForEach(CallAction.allCases, id: \.self) { callAction in
                        Text(callAction.rawValue).tag(callAction)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

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
                    ForEach(CallFlow.allCases, id: \.self) { callFlow in
                        Text(callFlow.rawValue)
                            .tag(callFlow)
                            .accessibility(identifier: callFlow.rawValue)
                    }
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
        .modifier(
            DemoCallingViewModifier(
                text: $text,
                viewModel: viewModel
            )
        )
        .onReceive(appState.$currentUser) { currentUser in
            self.callAction = currentUser?.type == .regular ? callAction : .joinCall
            self.callFlow = currentUser?.type == .regular ? callFlow : .joinImmediately
        }
    }
}
