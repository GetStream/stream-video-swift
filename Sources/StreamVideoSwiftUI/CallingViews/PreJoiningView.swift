//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LobbyView: View {
    
    @ObservedObject var callViewModel: CallViewModel
    @StateObject var viewModel = LobbyViewModel()
    @StateObject var microphoneChecker = MicrophoneChecker()
    
    var callId: String
    var callType: String
    var callParticipants: [User]
        
    public init(
        callViewModel: CallViewModel,
        callId: String,
        callType: String,
        callParticipants: [User]
    ) {
        self.callViewModel = callViewModel
        self.callId = callId
        self.callType = callType
        self.callParticipants = callParticipants
    }
    
    public var body: some View {
        LobbyContentView(
            callViewModel: callViewModel,
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            callId: callId,
            callType: callType,
            callParticipants: callParticipants
        )
    }
}

struct LobbyContentView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    
    var callId: String
    var callType: String
    var callParticipants: [User]
    
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
                        callViewModel: callViewModel,
                        microphoneChecker: microphoneChecker,
                        availableSize: reader.size
                    )
                    
                    if !microphoneChecker.hasDecibelValues {
                        Text(L10n.WaitingRoom.Mic.notWorking)
                            .font(.caption)
                            .foregroundColor(colors.text)
                    }
                                        
                    CallSettingsView(callViewModel: callViewModel)
                    
                    JoinCallView(
                        callViewModel: callViewModel,
                        callId: callId,
                        callType: callType,
                        callParticipants: callParticipants
                    )
                }
                .padding()
                
                TopRightView {
                    Button {
                        callViewModel.callingState = .idle
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
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    var availableSize: CGSize
    
    var body: some View {
        Group {
            if let image = viewModel.viewfinderImage, callViewModel.callSettings.videoOn {
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
                .opacity(callViewModel.callSettings.videoOn ? 0 : 1)
                .frame(width: availableSize.width - 32, height: availableSize.height / 2)
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    MicrophoneCheckView(
                        decibels: microphoneChecker.decibels,
                        microphoneOn: callViewModel.callSettings.audioOn,
                        hasDecibelValues: microphoneChecker.hasDecibelValues
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
    @ObservedObject var callViewModel: CallViewModel
    
    var callId: String
    var callType: String
    var callParticipants: [User]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(L10n.WaitingRoom.description)")
                .font(.headline)
                .accessibility(identifier: "otherParticipantsCount")
                .streamAccessibility(value: "\(otherParticipantsCount)")
            
            Button {
                if case .lobby(_) = callViewModel.callingState {
                    callViewModel.startCall(callId: callId, type: callType, members: callParticipants)
                }
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
    
    @ObservedObject var callViewModel: CallViewModel
    
    private let iconSize: CGFloat = 50
    
    var body: some View {
        HStack(spacing: 32) {
            Button {
                let callSettings = callViewModel.callSettings
                callViewModel.callSettings = CallSettings(
                    audioOn: !callSettings.audioOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            } label: {
                CallIconView(
                    icon: (callViewModel.callSettings.audioOn ? images.micTurnOn : images.micTurnOff),
                    size: iconSize,
                    iconStyle: (callViewModel.callSettings.audioOn ? .primary : .transparent)
                )
                .accessibility(identifier: "microphoneToggle")
                .streamAccessibility(value: callViewModel.callSettings.audioOn ? "1" : "0")
            }

            Button {
                let callSettings = callViewModel.callSettings
                callViewModel.callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            } label: {
                CallIconView(
                    icon: (callViewModel.callSettings.videoOn ? images.videoTurnOn : images.videoTurnOff),
                    size: iconSize,
                    iconStyle: (callViewModel.callSettings.videoOn ? .primary : .transparent)
                )
                .accessibility(identifier: "cameraToggle")
                .streamAccessibility(value: callViewModel.callSettings.videoOn ? "1" : "0")
            }
        }
        .padding()
    }
}
