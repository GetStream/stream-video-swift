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
        struct CustomLobbyView: View {

            @StateObject var viewModel: LobbyViewModel
            @StateObject var microphoneChecker = MicrophoneChecker()

            var callId: String
            var callType: String
            @Binding var callSettings: CallSettings
            var onJoinCallTap: () -> Void
            var onCloseLobby: () -> Void

            public init(
                callId: String,
                callType: String,
                callSettings: Binding<CallSettings>,
                onJoinCallTap: @escaping () -> Void,
                onCloseLobby: @escaping () -> Void
            ) {
                self.callId = callId
                self.callType = callType
                self.onJoinCallTap = onJoinCallTap
                self.onCloseLobby = onCloseLobby
                _callSettings = callSettings
                _viewModel = StateObject(
                    wrappedValue: LobbyViewModel(
                        callType: callType,
                        callId: callId
                    )
                )
            }

            public var body: some View {
                CustomLobbyContentView(
                    viewModel: viewModel,
                    microphoneChecker: microphoneChecker,
                    callId: callId,
                    callType: callType,
                    callSettings: $callSettings,
                    onJoinCallTap: onJoinCallTap,
                    onCloseLobby: onCloseLobby
                )
            }
        }

        struct CustomLobbyContentView: View {

            @Injected(\.images) var images
            @Injected(\.colors) var colors
            @Injected(\.streamVideo) var streamVideo

            @ObservedObject var viewModel: LobbyViewModel
            @ObservedObject var microphoneChecker: MicrophoneChecker

            var callId: String
            var callType: String
            @Binding var callSettings: CallSettings
            var onJoinCallTap: () -> Void
            var onCloseLobby: () -> Void

            var body: some View {
                GeometryReader { reader in
                    ZStack {
                        VStack {
                            Spacer()
                            Text("Before Joining")
                                .font(.title)
                                .foregroundColor(colors.text)
                                .bold()

                            Text("Setup your audio and video")
                                .font(.body)
                                .foregroundColor(Color(colors.textLowEmphasis))

                            CameraCheckView(
                                viewModel: viewModel,
                                microphoneChecker: microphoneChecker,
                                callSettings: callSettings,
                                availableSize: reader.size
                            )

                            if microphoneChecker.isSilent {
                                Text("Your microphone doesn't seem to be working. Make sure you have all permissions accepted.")
                                    .font(.caption)
                                    .foregroundColor(colors.text)
                            }

                            CallSettingsView(callSettings: $callSettings)

                            JoinCallView(
                                callId: callId,
                                callType: callType,
                                callParticipants: viewModel.participants,
                                onJoinCallTap: onJoinCallTap
                            )
                        }
                        .padding()

                        TopRightView {
                            Button {
                                onCloseLobby()
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(colors.text)
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
                }
                .onAppear {
                    viewModel.startCamera(front: true)
                }
                .onDisappear {
                    viewModel.stopCamera()
                }
            }
        }

        struct CameraCheckView: View {

            @Injected(\.images) var images
            @Injected(\.colors) var colors
            @Injected(\.streamVideo) var streamVideo

            @ObservedObject var viewModel: LobbyViewModel
            @ObservedObject var microphoneChecker: MicrophoneChecker
            var callSettings: CallSettings
            var availableSize: CGSize

            var body: some View {
                Group {
                    if let image = viewModel.viewfinderImage, callSettings.videoOn {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: availableSize.width - 32, height: cameraSize)
                            .cornerRadius(16)
                            .accessibility(identifier: "cameraCheckView")
                            .streamAccessibility(value: "1")
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(colors.lobbySecondaryBackground)
                                .frame(width: availableSize.width - 32, height: cameraSize)
                                .cornerRadius(16)

                            if #available(iOS 14.0, *) {
                                UserAvatar(imageURL: streamVideo.user.imageURL, size: 80)
                                    .accessibility(identifier: "cameraCheckView")
                                    .streamAccessibility(value: "0")
                            }
                        }
                        .opacity(callSettings.videoOn ? 0 : 1)
                        .frame(width: availableSize.width - 32, height: cameraSize)
                    }
                }
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
                        .padding()
                    }
                )
            }

            private var cameraSize: CGFloat {
                if !viewModel.participants.isEmpty {
                    return availableSize.height / 2 - 64
                } else {
                    return availableSize.height / 2
                }
            }
        }

        struct CallSettingsView: View {

            @Injected(\.images) var images

            @Binding var callSettings: CallSettings

            private let iconSize: CGFloat = 50

            var body: some View {
                HStack(spacing: 32) {
                    Button {
                        callSettings = CallSettings(
                            audioOn: !callSettings.audioOn,
                            videoOn: callSettings.videoOn,
                            speakerOn: callSettings.speakerOn
                        )
                    } label: {
                        CallIconView(
                            icon: (callSettings.audioOn ? images.micTurnOn : images.micTurnOff),
                            size: iconSize,
                            iconStyle: (callSettings.audioOn ? .primary : .transparent)
                        )
                        .accessibility(identifier: "microphoneToggle")
                        .streamAccessibility(value: callSettings.audioOn ? "1" : "0")
                    }

                    Button {
                        callSettings = CallSettings(
                            audioOn: callSettings.audioOn,
                            videoOn: !callSettings.videoOn,
                            speakerOn: callSettings.speakerOn
                        )
                    } label: {
                        CallIconView(
                            icon: (callSettings.videoOn ? images.videoTurnOn : images.videoTurnOff),
                            size: iconSize,
                            iconStyle: (callSettings.videoOn ? .primary : .transparent)
                        )
                        .accessibility(identifier: "cameraToggle")
                        .streamAccessibility(value: callSettings.videoOn ? "1" : "0")
                    }
                }
                .padding()
            }
        }
        
        struct JoinCallView: View {

            @Injected(\.colors) var colors

            var callId: String
            var callType: String
            var callParticipants: [User]
            var onJoinCallTap: () -> Void

            var body: some View {
                VStack(spacing: 16) {
                    Text("You are about to join a call.")
                        .font(.headline)
                        .accessibility(identifier: "otherParticipantsCount")
                        .streamAccessibility(value: "\(otherParticipantsCount)")

                    if #available(iOS 14, *) {
                        if !callParticipants.isEmpty {
                            ParticipantsInCallView(
                                callParticipants: callParticipants
                            )
                        }
                    }

                    Button {
                        onJoinCallTap()
                    } label: {
                        Text("Join Call")
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

            private var otherParticipantsCount: Int {
                let count = callParticipants.count - 1
                if count > 0 {
                    return count
                } else {
                    return 0
                }
            }
        }

        @available(iOS 14.0, *)
        struct ParticipantsInCallView: View {

            struct ParticipantInCall: Identifiable {
                let id: String
                let user: User
            }

            var callParticipants: [User]

            var participantsInCall: [ParticipantInCall] {
                var result = [ParticipantInCall]()
                for (index, participant) in callParticipants.enumerated() {
                    let id = "\(index)-\(participant.id)"
                    let participant = ParticipantInCall(id: id, user: participant)
                    result.append(participant)
                }
                return result
            }

            private let viewSize: CGFloat = 64

            var body: some View {
                VStack(spacing: 4) {
                    Text("There are \(callParticipants.count) more people in the call.")
                        .font(.headline)

                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(participantsInCall) { participant in
                                VStack {
                                    UserAvatar(
                                        imageURL: participant.user.imageURL,
                                        size: 40
                                    )
                                    Text(participant.user.name)
                                        .font(.caption)
                                }
                                .frame(width: viewSize, height: viewSize)
                            }
                        }
                    }
                }
            }
        }
    }
}
