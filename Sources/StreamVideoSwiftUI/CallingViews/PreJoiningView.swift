//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LobbyView: View {
    
    @StateObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker = InjectedValues[\.microphoneChecker]

    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> ()
    var onCloseLobby: () -> ()
        
    public init(
        viewModel: LobbyViewModel? = nil,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> (),
        onCloseLobby: @escaping () -> ()
    ) {
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
    }
    
    public var body: some View {
        LobbyContentView(
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

struct LobbyContentView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker
    
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> ()
    var onCloseLobby: () -> ()
    
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
                    callSettings: callSettings
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
                    callParticipants: viewModel.participants,
                    onJoinCallTap: onJoinCallTap
                )
            }
            .padding()
        }
        .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.startCamera(front: true)
            if callSettings.audioOn { microphoneChecker.startListening() }
            else { microphoneChecker.stopListening() }
        }
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
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

                        if #available(iOS 14.0, *) {
                            UserAvatar(imageURL: streamVideo.user.imageURL, size: 80)
                                .accessibility(identifier: "cameraCheckView")
                                .streamAccessibility(value: "0")
                        }
                    }
                    .opacity(callSettings.videoOn ? 0 : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
}

struct JoinCallView: View {
    
    @Injected(\.colors) var colors
    
    var callId: String
    var callType: String
    var callParticipants: [User]
    var onJoinCallTap: () -> ()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(waitingRoomDescription)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(identifier: "otherParticipantsCount")
                .streamAccessibility(value: "\(otherParticipantsCount)")
            
            if #available(iOS 14, *) {
                if callParticipants.count > 0 {
                    ParticipantsInCallView(
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
        return "\(L10n.WaitingRoom.description) \(L10n.WaitingRoom.numberOfParticipants(callParticipants.count))"
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
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(participantsInCall) { participant in
                    VStack {
                        if let imageURL = participant.user.imageURL {
                            UserAvatar(imageURL: imageURL, size: 40)
                        } else {
                            CircledTitleView(
                                title: participant.user.name.isEmpty ? participant.user.id : String(participant.user.name.uppercased().first!),
                                size: 40
                            )
                        }
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

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct SizeModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color
                .clear
                .preference(key: SizePreferenceKey.self, value: geometry.size)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func body(content: Content) -> some View {
        content.overlay(sizeView)
    }
}
