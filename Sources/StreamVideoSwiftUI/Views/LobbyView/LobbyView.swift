//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LobbyView<Factory: ViewFactory>: View {

    @Injected(\.callAudioRecorder) private var callAudioRecorder

    @StateObject var viewModel: LobbyViewModel
    @StateObject var microphoneChecker = MicrophoneChecker()

    var viewFactory: Factory
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
        
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: LobbyViewModel? = nil,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobby: @escaping () -> Void
    ) {
        self.viewFactory = viewFactory
        self.callId = callId
        self.callType = callType
        self.onJoinCallTap = onJoinCallTap
        self.onCloseLobby = onCloseLobby
        _callSettings = callSettings
        _viewModel = StateObject(
            wrappedValue: viewModel ?? LobbyViewModel(
                callType: callType,
                callId: callId
            )
        )
        let microphoneCheckerInstance = MicrophoneChecker()
        _microphoneChecker = .init(wrappedValue: microphoneCheckerInstance)
    }
    
    public var body: some View {
        LobbyContentView(
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            viewFactory: viewFactory,
            callId: callId,
            callType: callType,
            callSettings: $callSettings,
            onJoinCallTap: onJoinCallTap,
            onCloseLobby: onCloseLobby
        )
        .onChange(of: callSettings) { newValue in
            Task {
                newValue.audioOn
                    ? await callAudioRecorder.startRecording(ignoreActiveCall: true)
                    : await callAudioRecorder.stopRecording()
            }
        }
        .onAppear {
            Task {
                callSettings.audioOn
                    ? await callAudioRecorder.startRecording(ignoreActiveCall: true)
                    : await callAudioRecorder.stopRecording()
            }
        }
    }
}

struct LobbyContentView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.callAudioRecorder) private var callAudioRecorder

    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker

    var viewFactory: Factory
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()
                    Button {
                        Task { await callAudioRecorder.stopRecording() }
                        onCloseLobby()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(colors.text)
                    }
                }

                VStack(alignment: .center) {
                    Text(L10n.WaitingRoom.title)
                        .font(.title)
                        .foregroundColor(colors.text)
                        .bold()

                    Text(L10n.WaitingRoom.subtitle)
                        .font(.body)
                        .foregroundColor(Color(colors.textLowEmphasis))
                }
            }
            .padding()
            .zIndex(1)

            VStack {
                CameraCheckView(
                    viewModel: viewModel,
                    microphoneChecker: microphoneChecker,
                    viewFactory: viewFactory,
                    callSettings: callSettings
                )

                if microphoneChecker.isSilent {
                    Text(L10n.WaitingRoom.Mic.notWorking)
                        .font(.caption)
                        .foregroundColor(colors.text)
                }

                CallSettingsView(callSettings: $callSettings)

                JoinCallView(
                    viewFactory: viewFactory,
                    callId: callId,
                    callType: callType,
                    callParticipants: viewModel.participants,
                    onJoinCallTap: onJoinCallTap
                )
            }
            .padding()
        }
        .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { viewModel.startCamera(front: true) }
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
        }
    }
}
