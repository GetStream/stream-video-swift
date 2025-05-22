//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Intents
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DetailedCallingView<Factory: ViewFactory>: View {
    enum CallAction: String, Equatable, CaseIterable {
        case startCall = "Start a call"
        case joinCall = "Join a call"
    }

    enum CallFlow: String, Equatable, CaseIterable {
        case joinImmediately = "Join immediately"
        case ringEvents = "Ring events"
        case lobby = "Lobby"
    }

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.appearance) var appearance

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject private var appState = AppState.shared

    private var viewFactory: Factory
    private let imageSize: CGFloat = 32

    private var participants: [User] {
        AppState.shared.users.filter { $0.id != streamVideo.user.id }
    }

    private var makeCallEnabled: Bool {
        text.isEmpty || participants.isEmpty
    }

    private var members: [Member] {
        var members: [Member] = selectedParticipants.map {
            Member(user: $0)
        }
        if !selectedParticipants.contains(streamVideo.user) {
            let currentUser = streamVideo.user
            let member = Member(user: currentUser)
            members.append(member)
        }
        return members
    }

    @State private var text: String
    @State private var callType: String
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

    init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel,
        callId: String
    ) {
        self.viewFactory = viewFactory
        _text = .init(initialValue: callId)
        _callType = .init(initialValue: {
            guard
                !AppState.shared.deeplinkInfo.callId.isEmpty,
                !AppState.shared.deeplinkInfo.callType.isEmpty
            else {
                return AppEnvironment.preferredCallType ?? .default
            }

            return AppState.shared.deeplinkInfo.callType
        }())
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            DemoCallingTopView(callViewModel: viewModel)

            VStack(spacing: 0) {
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

                if canStartCall {
                    Picker("Call action", selection: $callAction) {
                        ForEach(CallAction.allCases, id: \.self) { callAction in
                            Text(callAction.rawValue).tag(callAction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(8)
                }
            }
            .background(Color(appearance.colors.background))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))

            if callAction == .startCall {
                participantsListView
                    .accessibility(identifier: "participantList")

                Picker("Call flow", selection: $callFlow) {
                    ForEach(CallFlow.allCases, id: \.self) { callFlow in
                        Text(callFlow.rawValue)
                            .tag(callFlow)
                            .accessibility(identifier: callFlow.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                Spacer()
            }

            Button {
                resignFirstResponder()
                Task {
                    await setPreferredVideoCodec(for: text)
                    if callAction == .joinCall {
                        viewModel.joinCall(callType: callType, callId: text)
                    } else {
                        if callFlow == .lobby {
                            viewModel.enterLobby(
                                callType: callType,
                                callId: text,
                                members: members
                            )
                        } else {
                            viewModel.startCall(
                                callType: callType,
                                callId: text,
                                members: members,
                                ring: callFlow == .ringEvents,
                                video: viewModel.callSettings.videoOn
                            )
                        }
                    }
                }
            } label: {
                CallButtonView(
                    title: callAction == .joinCall ? "Join Call" : "Start Call",
                    isDisabled: isActionDisabled
                )
            }
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
            callAction = currentUser?.type == .regular ? callAction : .joinCall
            callFlow = currentUser?.type == .regular ? callFlow : .joinImmediately
        }
    }

    @ViewBuilder
    private var participantsListView: some View {
        List {
            Section {
                ForEach(participants) { participant in
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
                                viewFactory.makeUserAvatar(
                                    participant,
                                    with: .init(size: imageSize)
                                )
                            }

                            if selectedParticipants.contains(participant) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .foregroundColor(appearance.colors.text)
                        .listRowBackground(Color.clear)
                    }
                    .padding(8)
                    .listRowBackground(Color.clear)
                }
            } header: {
                Text("Built-In")
            }
        }
        .listStyle(.plain)
        .background(Color.clear)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func setPreferredVideoCodec(for callId: String) async {
        let call = streamVideo.call(callType: callType, callId: callId)
        await call.updatePublishOptions(
            preferredVideoCodec: AppEnvironment.preferredVideoCodec.videoCodec
        )
    }
}
