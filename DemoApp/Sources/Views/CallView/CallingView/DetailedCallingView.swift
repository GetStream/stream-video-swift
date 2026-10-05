//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        case joinImmediately = "Join now"
        case ringEvents = "Ring events"
        case lobby = "Lobby"
        case joinAndRing = "Join and ring"
    }

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

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
    @State var addUserShown = false

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
        VStack(spacing: layout.spacingXs) {
            DemoCallingTopView(callViewModel: viewModel)

            VStack(spacing: 0) {
                HStack(spacing: layout.spacingXs) {
                    TextField("Call ID", text: $text)
                        .foregroundColor(Color(colors.inputTextDefault))
                        .padding(.all, layout.spacingSm)
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
                                .foregroundColor(Color(colors.inputTextIcon))
                        }
                        .padding(.trailing, layout.spacingMd)
                    }
                }

                if canStartCall {
                    Picker("Call action", selection: $callAction) {
                        ForEach(CallAction.allCases, id: \.self) { callAction in
                            Text(callAction.rawValue).tag(callAction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(layout.spacingXs)
                }
            }
            .background(Color(colors.backgroundCoreSurfaceDefault))
            .clipShape(RoundedRectangle(cornerRadius: layout.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: layout.radiusMd)
                    .stroke(Color(colors.borderCoreDefault), lineWidth: 1)
            )

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
                        await setEncryptionIfNeeded(for: text)
                        viewModel.joinCall(
                            callType: callType,
                            callId: text,
                            encryption: AppEnvironment.EncryptionKeys.shared.encryptionRequest
                        )
                    } else {
                        if callFlow == .lobby {
                            viewModel.enterLobby(
                                callType: callType,
                                callId: text,
                                members: members
                            )
                        } else if callFlow == .joinAndRing {
                            await setEncryptionIfNeeded(for: text)
                            viewModel.joinAndRingCall(
                                callType: callType,
                                callId: text,
                                members: members,
                                video: viewModel.callSettings.videoOn,
                                encryption: AppEnvironment.EncryptionKeys.shared.encryptionRequest
                            )
                        } else {
                            await setEncryptionIfNeeded(for: text)
                            let highScaleHint = AppEnvironment
                                .highScaleLivestreamPublisherHint
                                .value
                            viewModel.startCall(
                                callType: callType,
                                callId: text,
                                members: members,
                                ring: callFlow == .ringEvents,
                                highScaleLivestreamPublisherHint: highScaleHint,
                                video: viewModel.callSettings.videoOn,
                                encryption: AppEnvironment.EncryptionKeys.shared.encryptionRequest
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
            self.callAction = currentUser?.type == .regular ? callAction : .joinCall
            self.callFlow = currentUser?.type == .regular ? callFlow : .joinImmediately
        }
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private var callSettingsView: some View {
        CallSettingsMenuView(viewModel)
    }

    @ViewBuilder
    private var participantsListView: some View {
        List {
            Section {
                ForEach(participants) { participant in
                    LoginItemView(
                        selected: .init(
                            get: { selectedParticipants.contains(participant) },
                            set: { _ in }
                        )
                    ) {
                        if selectedParticipants.contains(participant) {
                            selectedParticipants.removeAll { user in
                                user.id == participant.id
                            }
                        } else {
                            selectedParticipants.append(participant)
                        }
                    } title: {
                        Text(participant.name)
                    } icon: {
                        AppUserView(user: participant)
                    }
                    .foregroundColor(Color(colors.textPrimary))
                    .accessibilityIdentifier("participantItem")
                }
            } header: {
                HStack(spacing: layout.spacingXs) {
                    Text("Built-In")
                    Spacer()
                    HStack(spacing: layout.spacingXs) {
                        callSettingsView
                        Button {
                            addUserShown = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    .foregroundColor(Color(colors.textPrimary))
                }
            }
        }
        .listStyle(.plain)
        .background(Color(colors.backgroundCoreApp))
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $addUserShown, onDismiss: {}) {
            DemoAddUserView()
        }
    }

    private func setPreferredVideoCodec(for callId: String) async {
        let call = streamVideo.call(
            callType: callType,
            callId: callId,
            callSettings: viewModel.callSettings
        )
        await call.updatePublishOptions(
            preferredVideoCodec: AppEnvironment.preferredVideoCodec.videoCodec
        )
    }

    private func setEncryptionIfNeeded(for callId: String) async {
        let call = streamVideo.call(
            callType: callType,
            callId: callId,
            callSettings: viewModel.callSettings
        )
        await AppEnvironment.EncryptionKeys.shared.attachIfNeeded(
            to: call,
            userId: streamVideo.user.id
        )
    }
}
