//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LobbyView: View {
    
    @StateObject var viewModel = LobbyViewModel()
    @StateObject var microphoneChecker = MicrophoneChecker()
    
    var callId: String
    var callType: String
    var callParticipants: [Member]
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> ()
    var onCloseLobby: () -> ()
        
    public init(
        callId: String,
        callType: String,
        callParticipants: [Member],
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> (),
        onCloseLobby: @escaping () -> ()
    ) {
        self.callId = callId
        self.callType = callType
        self.callParticipants = callParticipants
        self.onJoinCallTap = onJoinCallTap
        self.onCloseLobby = onCloseLobby
        _callSettings = callSettings
    }
    
    public var body: some View {
        LobbyContentView(
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            callId: callId,
            callType: callType,
            callParticipants: callParticipants,
            callSettings: $callSettings,
            onJoinCallTap: onJoinCallTap,
            onCloseLobby: onCloseLobby
        )
    }
}

struct LobbyContentView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    
    var callId: String
    var callType: String
    var callParticipants: [Member]
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> ()
    var onCloseLobby: () -> ()
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                VStack {
                    Spacer()
                    Text(L10n.WaitingRoom.title)
                        .font(.title)
                        .foregroundColor(colors.text)
                        .bold()
                    
                    Text(L10n.WaitingRoom.subtitle)
                        .font(.body)
                        .foregroundColor(Color(colors.textLowEmphasis))
                    
                    CameraCheckView(
                        viewModel: viewModel,
                        microphoneChecker: microphoneChecker,
                        callSettings: callSettings,
                        availableSize: reader.size
                    )
                    
                    if microphoneChecker.isSilent {
                        Text(L10n.WaitingRoom.Mic.notWorking)
                            .font(.caption)
                            .foregroundColor(colors.text)
                    }
                                        
                    CallSettingsView(callSettings: $callSettings)
                    
                    JoinCallView(
                        callId: callId,
                        callType: callType,
                        callParticipants: callParticipants,
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
                    .frame(width: availableSize.width - 32, height: availableSize.height / 2)
                    .cornerRadius(16)
                    .accessibility(identifier: "cameraCheckView")
                    .streamAccessibility(value: "1")
            } else {
                ZStack {
                    Rectangle()
                        .fill(colors.lobbySecondaryBackground)
                        .frame(width: availableSize.width - 32, height: availableSize.height / 2)
                        .cornerRadius(16)

                    if #available(iOS 14.0, *) {
                        UserAvatar(imageURL: streamVideo.user.imageURL, size: 80)
                            .accessibility(identifier: "cameraCheckView")
                            .streamAccessibility(value: "0")
                    }
                }
                .opacity(callSettings.videoOn ? 0 : 1)
                .frame(width: availableSize.width - 32, height: availableSize.height / 2)
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    MicrophoneCheckView(
                        audioLevels: microphoneChecker.audioLevels,
                        microphoneOn: callSettings.audioOn,
                        isSilent: microphoneChecker.isSilent
                    )
                    .accessibility(identifier: "microphoneCheckView")
                    Spacer()
                }
                .padding()
            }
        )
    }
}

struct JoinCallView: View {
    
    @Injected(\.colors) var colors
    
    var callId: String
    var callType: String
    var callParticipants: [Member]
    var onJoinCallTap: () -> ()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(L10n.WaitingRoom.description)")
                .font(.headline)
                .accessibility(identifier: "otherParticipantsCount")
                .streamAccessibility(value: "\(otherParticipantsCount)")
            
            Button {
                onJoinCallTap()
            } label: {
                Text(L10n.WaitingRoom.join)
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
