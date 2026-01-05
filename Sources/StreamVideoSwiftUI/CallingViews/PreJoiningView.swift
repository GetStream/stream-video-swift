//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LobbyView<Factory: ViewFactory>: View {

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
        .onChange(of: callSettings) { viewModel.didUpdate(callSettings: $0) }
        .onAppear { viewModel.didUpdate(callSettings: callSettings) }
    }
}

struct LobbyContentView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
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

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    var viewFactory: Factory
    var callSettings: CallSettings

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let image = viewModel.viewfinderImage, callSettings.videoOn {
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
}

struct JoinCallView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var callId: String
    var callType: String
    var callParticipants: [User]
    var onJoinCallTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(waitingRoomDescription)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(identifier: "callParticipantsCount")
                .streamAccessibility(value: "\(callParticipants.count)")
            
            if #available(iOS 14, *) {
                if !callParticipants.isEmpty {
                    ParticipantsInCallView(
                        viewFactory: viewFactory,
                        callParticipants: callParticipants
                    )
                }
            }
            
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
    
    private var waitingRoomDescription: String {
        "\(L10n.WaitingRoom.description) \(L10n.WaitingRoom.numberOfParticipants(callParticipants.count))"
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
        }
        .padding()
    }
}

@available(iOS 14.0, *)
struct ParticipantsInCallView<Factory: ViewFactory>: View {

    struct ParticipantInCall: Identifiable {
        let id: String
        let user: User
    }

    var viewFactory: Factory
    var callParticipants: [User]

    init(
        viewFactory: Factory,
        callParticipants: [User]
    ) {
        self.viewFactory = viewFactory
        self.callParticipants = callParticipants
    }

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
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(participantsInCall) { participant in
                    VStack {
                        viewFactory.makeUserAvatar(
                            participant.user,
                            with: .init(size: 40) {
                                AnyView(
                                    CircledTitleView(
                                        title: participant.user.name.isEmpty ? participant.user
                                            .id : String(participant.user.name.uppercased().first!),
                                        size: 40
                                    )
                                )
                            }
                        )

                        Text(participant.user.name)
                            .font(.caption)
                    }
                    .frame(width: viewSize, height: viewSize)
                }
            }
        }
        .frame(height: viewSize)
    }
}
