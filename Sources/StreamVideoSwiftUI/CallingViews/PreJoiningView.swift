//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct PreJoiningView: View {
    
    @ObservedObject var callViewModel: CallViewModel
    @StateObject var viewModel = PreJoiningViewModel()
    @StateObject var microphoneChecker = MicrophoneChecker()
    
    var callId: String
    var callType: String?
    var callParticipants: [User]
        
    public init(
        callViewModel: CallViewModel,
        callId: String,
        callType: String?,
        callParticipants: [User]
    ) {
        _callViewModel = ObservedObject(wrappedValue: callViewModel)
        self.callId = callId
        self.callType = callType
        self.callParticipants = callParticipants
    }
    
    public var body: some View {
        PreJoiningContentView(
            callViewModel: callViewModel,
            viewModel: viewModel,
            microphoneChecker: microphoneChecker,
            callId: callId,
            callType: callType,
            callParticipants: callParticipants
        )
    }
}

struct PreJoiningContentView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var viewModel: PreJoiningViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    
    var callId: String
    var callType: String?
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
                    
                    if viewModel.connectionQuality == .poor {
                        Text(L10n.WaitingRoom.connectionIssues)
                            .font(.caption)
                            .foregroundColor(colors.text)
                    }
                    
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
            .background(colors.waitingRoomBackground.edgesIgnoringSafeArea(.all))
        }
        .onReceive(callViewModel.$edgeServer, perform: { edgeServer in
            viewModel.latencyURL = edgeServer?.latencyURL
        })
        .onAppear {
            viewModel.startCamera(front: true)
        }
    }
}

struct CameraCheckView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: PreJoiningViewModel
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
            } else {
                ZStack {
                    Rectangle()
                        .fill(colors.waitingRoomSecondaryBackground)
                        .frame(width: availableSize.width - 32, height: availableSize.height / 2)
                        .cornerRadius(16)

                    if #available(iOS 14.0, *) {
                        LazyImage(url: streamVideo.user.imageURL)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
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
                    Spacer()
                    ConnectionQualityIndicator(connectionQuality: viewModel.connectionQuality)
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
    var callType: String?
    var callParticipants: [User]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(L10n.WaitingRoom.description) \(otherParticipantsCount) \(L10n.WaitingRoom.numberOfParticipants)")
                .font(.headline)
            
            Button {
                callViewModel.startCall(callId: callId, type: callType, participants: callParticipants)
            } label: {
                Text(L10n.WaitingRoom.join)
                    .bold()
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(colors.primaryButtonBackground)
            .cornerRadius(16)
            .foregroundColor(.white)
        }
        .padding()
        .background(colors.waitingRoomSecondaryBackground)
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
            }
        }
        .padding()
    }
}
