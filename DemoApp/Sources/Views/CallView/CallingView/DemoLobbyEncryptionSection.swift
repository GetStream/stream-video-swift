//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

/// Demo `ViewFactory.makeLobbyView` override. Same lobby as the SDK, with an
/// extra encryption control on the call-settings row.
struct DemoLobbyView: View {
    @Injected(\.colors) private var colors
    @Injected(\.streamVideo) private var streamVideo

    @StateObject private var lobbyViewModel: LobbyViewModel
    @StateObject private var microphoneChecker = MicrophoneChecker()

    var viewFactory: DemoAppViewFactory
    var viewModel: CallViewModel
    var lobbyInfo: LobbyInfo
    @Binding var callSettings: CallSettings

    init(
        viewFactory: DemoAppViewFactory,
        viewModel: CallViewModel,
        lobbyInfo: LobbyInfo,
        callSettings: Binding<CallSettings>
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.lobbyInfo = lobbyInfo
        _callSettings = callSettings
        _lobbyViewModel = StateObject(
            wrappedValue: LobbyViewModel(
                callType: lobbyInfo.callType,
                callId: lobbyInfo.callId
            )
        )
    }

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()
                    Button {
                        viewModel.hangUp()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.text)
                    }
                }

                VStack(alignment: .center) {
                    Text(Self.localized("waiting-room.title"))
                        .font(.title)
                        .foregroundColor(colors.text)
                        .bold()

                    Text(Self.localized("waiting-room.subtitle"))
                        .font(.body)
                        .foregroundColor(Color(colors.textLowEmphasis))
                }
            }
            .padding()
            .zIndex(1)

            VStack {
                cameraPreview

                if microphoneChecker.isSilent {
                    Text(Self.localized("waiting-room.mic.not-working"))
                        .font(.caption)
                        .foregroundColor(colors.text)
                }

                DemoCallSettingsView(callSettings: $callSettings)

                joinCard
            }
            .padding()
        }
        .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            lobbyViewModel.startCamera(front: true)
            lobbyViewModel.didUpdate(callSettings: callSettings)
        }
        .onDisappear {
            lobbyViewModel.stopCamera()
            lobbyViewModel.cleanUp()
        }
        .onChange(of: callSettings) { lobbyViewModel.didUpdate(callSettings: $0) }
    }

    private var cameraPreview: some View {
        GeometryReader { proxy in
            Group {
                if let image = lobbyViewModel.viewfinderImage, callSettings.videoOn {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .accessibility(identifier: "cameraCheckView")
                        .streamAccessibility(value: "1")
                } else {
                    ZStack {
                        Rectangle()
                            .fill(colors.lobbySecondaryBackground)
                        viewFactory.makeUserAvatar(
                            streamVideo.user,
                            with: .init(size: 80)
                        )
                        .accessibility(identifier: "cameraCheckView")
                        .streamAccessibility(value: "0")
                    }
                    .opacity(callSettings.videoOn ? 0 : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        MicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent,
                            isPinned: false
                        )
                        .accessibility(identifier: "microphoneCheckView")
                        Spacer()
                    }
                }
            )
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var joinCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(waitingRoomDescription)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(identifier: "callParticipantsCount")
                .streamAccessibility(value: "\(lobbyViewModel.participants.count)")

            if !lobbyViewModel.participants.isEmpty {
                participantsStrip
            }

            Button(action: join) {
                Text(Self.localized("waiting-room.join"))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .accessibility(identifier: "joinCall")
            }
            .frame(height: 50)
            .background(colors.primaryButtonBackground)
            .cornerRadius(16)
            .foregroundColor(.white)
        }
        .padding()
        .background(colors.lobbySecondaryBackground)
        .cornerRadius(16)
    }

    private var participantsStrip: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(
                    Array(lobbyViewModel.participants.enumerated()),
                    id: \.offset
                ) { _, user in
                    VStack {
                        viewFactory.makeUserAvatar(user, with: .init(size: 40))
                        Text(user.name)
                            .font(.caption)
                    }
                    .frame(width: 64, height: 64)
                }
            }
        }
        .frame(height: 64)
    }

    private var waitingRoomDescription: String {
        let others = Self.localized(
            "waiting-room.number-of-participants",
            lobbyViewModel.participants.count
        )
        return "\(Self.localized("waiting-room.description")) \(others)"
    }

    private func join() {
        guard case .lobby = viewModel.callingState else { return }
        Task { @MainActor in
            let keys = AppEnvironment.EncryptionKeys.shared
            let call = streamVideo.call(
                callType: lobbyInfo.callType,
                callId: lobbyInfo.callId
            )
            await keys.attachIfNeeded(to: call, userId: streamVideo.user.id)
            viewModel.startCall(
                callType: lobbyInfo.callType,
                callId: lobbyInfo.callId,
                members: lobbyInfo.participants,
                encryption: keys.encryptionRequest
            )
        }
    }

    private static func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = Appearance.localizationProvider(key, "Localizable")
        guard !args.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

/// Shipping mic/camera row plus a demo-only encryption button.
private struct DemoCallSettingsView: View {
    @Injected(\.images) private var images

    @Binding var callSettings: CallSettings

    private let iconSize: CGFloat = 50

    var body: some View {
        HStack(spacing: 32) {
            StatelessMicrophoneIconView(
                call: nil,
                callSettings: callSettings,
                size: iconSize,
                controlStyle: .init(
                    enabled: .init(icon: images.micTurnOn, iconStyle: .primary),
                    disabled: .init(icon: images.micTurnOff, iconStyle: .transparent)
                )
            ) {
                callSettings = CallSettings(
                    audioOn: !callSettings.audioOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }

            StatelessVideoIconView(
                call: nil,
                callSettings: callSettings,
                size: iconSize,
                controlStyle: .init(
                    enabled: .init(icon: images.videoTurnOn, iconStyle: .primary),
                    disabled: .init(icon: images.videoTurnOff, iconStyle: .transparent)
                )
            ) {
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }

            DemoLobbyEncryptionButton()
        }
        .padding()
    }
}

private struct DemoLobbyEncryptionButton: View {
    @ObservedObject private var keys = AppEnvironment.EncryptionKeys.shared

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            CallIconView(
                icon: Image(systemName: lockSymbol),
                size: 50,
                iconStyle: keys.wantsEncryption ? .primary : .transparent
            )
        }
        .accessibility(identifier: "e2eeButton")
        .streamAccessibility(value: keys.wantsEncryption ? "1" : "0")
        .sheet(isPresented: $isPresented) {
            NavigationView {
                DemoLobbyEncryptionSection()
                    .navigationBarTitle("Encryption", displayMode: .inline)
                    .navigationBarItems(
                        trailing: Button("Done") { isPresented = false }
                    )
            }
            .navigationViewStyle(.stack)
        }
    }

    private var lockSymbol: String {
        if #available(iOS 16.0, *) {
            return "lock.shield"
        }
        return "lock.fill"
    }
}

struct DemoLobbyEncryptionSection: View {
    @Injected(\.colors) private var colors
    @ObservedObject private var keys = AppEnvironment.EncryptionKeys.shared

    var body: some View {
        Form {
            Section(
                footer: Text(
                    "Anyone with this key can join. Don't share it in a public post."
                )
            ) {
                Toggle(isOn: enabledBinding) {
                    HStack {
                        Image(systemName: lockSymbol)
                            .foregroundColor(colors.accentGreen)
                        Text("End-to-end encrypted")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: colors.accentGreen))
                .accessibility(identifier: "e2eeToggle")

                if keys.wantsEncryption {
                    HStack {
                        TextField("Shared key", text: passphraseBinding)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .accessibility(identifier: "e2eeKey")

                        Button(action: keys.generatePassphrase) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(
                                    Color(colors.textLowEmphasis)
                                )
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibility(identifier: "e2eeNewKey")
                    }
                }
            }
        }
    }

    private var lockSymbol: String {
        if #available(iOS 16.0, *) {
            return "lock.shield"
        }
        return "lock.fill"
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { keys.wantsEncryption },
            set: { enabled in
                if enabled {
                    if keys.shareKey.isEmpty {
                        keys.generatePassphrase()
                    }
                } else {
                    keys.clear()
                }
            }
        )
    }

    private var passphraseBinding: Binding<String> {
        Binding(
            get: { keys.passphrase },
            set: { keys.applyPassphraseField($0) }
        )
    }
}
