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
    @Injected(\.videoAppearance) var videoAppearance
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker

    var viewFactory: Factory
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: videoAppearance.tokens.layout.spacing2xl) {
                VStack(spacing: videoAppearance.tokens.layout.spacingSm) {
                    images.lobbyLanguage
                        .resizable()
                        .renderingMode(.template)
                        .frame(
                            width: videoAppearance.tokens.layout.iconSizeLg,
                            height: videoAppearance.tokens.layout.iconSizeLg
                        )
                        .foregroundColor(
                            Color(videoAppearance.tokens.colors.accentPrimary)
                        )
                        .accessibility(hidden: true)

                    Text(L10n.WaitingRoom.setup)
                        .font(videoAppearance.tokens.fonts.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(
                            Color(videoAppearance.tokens.colors.textPrimary)
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: videoAppearance.tokens.layout.spacing2xl) {
                    VStack(spacing: videoAppearance.tokens.layout.spacingSm) {
                        CameraCheckView(
                            viewModel: viewModel,
                            microphoneChecker: microphoneChecker,
                            viewFactory: viewFactory,
                            callSettings: callSettings
                        )
                        .aspectRatio(370.0 / 264.0, contentMode: .fit)

                        CallSettingsView(callSettings: $callSettings)
                    }

                    Button {
                        onJoinCallTap()
                    } label: {
                        Text(L10n.WaitingRoom.start)
                            .font(videoAppearance.tokens.fonts.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .accessibility(identifier: "joinCall")
                    }
                    .frame(
                        minHeight: videoAppearance.tokens.layout
                            .buttonHitTargetMinHeight
                    )
                    .background(
                        Color(videoAppearance.tokens.colors.buttonPrimaryBackground)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: videoAppearance.tokens.layout.buttonRadiusLg
                        )
                    )
                    .foregroundColor(
                        Color(
                            videoAppearance.tokens.colors
                                .buttonPrimaryTextOnAccent
                        )
                    )
                }
            }
            .padding(.horizontal, videoAppearance.tokens.layout.spacingMd)
            .padding(.vertical, videoAppearance.tokens.layout.spacing3xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            LobbyHeaderView(
                viewFactory: viewFactory,
                onCloseLobby: onCloseLobby
            )
        }
        .background(
            Color(videoAppearance.tokens.colors.backgroundCoreApp)
                .edgesIgnoringSafeArea(.all)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { viewModel.startCamera(front: true) }
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
        }
    }
}

private struct LobbyHeaderView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) private var streamVideo
    @Injected(\.videoAppearance) private var videoAppearance

    var viewFactory: Factory
    var onCloseLobby: () -> Void

    var body: some View {
        HStack(spacing: videoAppearance.tokens.layout.spacingXs) {
            viewFactory.makeUserAvatar(
                streamVideo.user,
                with: .init(size: 40)
            )
            .accessibility(hidden: true)

            Text(userDisplayName)
                .font(videoAppearance.tokens.fonts.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(
                    Color(videoAppearance.tokens.colors.textPrimary)
                )
                .lineLimit(1)

            Spacer(minLength: videoAppearance.tokens.layout.spacingXs)

            Button(action: onCloseLobby) {
                Image(systemName: "xmark")
                    .frame(
                        width: videoAppearance.tokens.layout.iconSizeMd,
                        height: videoAppearance.tokens.layout.iconSizeMd
                    )
            }
            .frame(
                minWidth: videoAppearance.tokens.layout.buttonHitTargetMinWidth,
                minHeight: videoAppearance.tokens.layout.buttonHitTargetMinHeight
            )
            .foregroundColor(
                Color(videoAppearance.tokens.colors.textPrimary)
            )
            .accessibility(label: Text(L10n.WaitingRoom.close))
        }
        .padding(.horizontal, videoAppearance.tokens.layout.spacingSm)
        .padding(.vertical, videoAppearance.tokens.layout.spacingSm)
    }

    private var userDisplayName: String {
        streamVideo.user.name.isEmpty
            ? streamVideo.user.id
            : streamVideo.user.name
    }
}

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.videoAppearance) var videoAppearance
    
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
                        .accessibility(
                            label: Text(L10n.WaitingRoom.cameraPreview)
                        )
                        .streamAccessibility(value: "1")
                } else {
                    ZStack {
                        Rectangle()
                            .fill(
                                Color(
                                    videoAppearance.tokens.colors
                                        .backgroundCoreSurfaceDefault
                                )
                            )

                        viewFactory.makeUserAvatar(
                            streamVideo.user,
                            with: .init(size: 80)
                        )
                        .accessibility(identifier: "cameraCheckView")
                        .accessibility(
                            label: Text(L10n.WaitingRoom.cameraPreview)
                        )
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
                        LobbyMicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent
                        )
                        .accessibility(identifier: "microphoneCheckView")
                        Spacer()
                    }
                }
                .padding(videoAppearance.tokens.layout.spacingXs)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: videoAppearance.tokens.layout.radius2xl
                )
                .stroke(
                    Color(videoAppearance.tokens.colors.accentPrimary),
                    lineWidth: 2
                )
            )
            .clipped()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: videoAppearance.tokens.layout.radius2xl
                )
            )
        }
    }
}

private struct LobbyMicrophoneCheckView: View {

    @Injected(\.images) private var images
    @Injected(\.permissions) private var permissions
    @Injected(\.streamVideo) private var streamVideo
    @Injected(\.videoAppearance) private var videoAppearance

    var audioLevels: [Float]
    var microphoneOn: Bool
    var isSilent: Bool

    @State private var hasMicrophoneAccess = false

    var body: some View {
        HStack(spacing: videoAppearance.tokens.layout.spacingXxs) {
            Text(userDisplayName)
                .font(videoAppearance.tokens.fonts.caption1)
                .lineLimit(1)

            if hasMicrophoneAccess, microphoneOn, !isSilent {
                HStack(spacing: 2) {
                    ForEach(Array(audioLevels.enumerated()), id: \.offset) {
                        _, level in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                Color(
                                    videoAppearance.colors
                                        .indicatorSoundIndicatorSpeaking
                                )
                            )
                            .frame(
                                width: 2,
                                height: max(CGFloat(level * 10), 2)
                            )
                    }
                }
                .frame(width: 16, height: 16)
            } else {
                images.micTurnOff
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
        .foregroundColor(
            Color(videoAppearance.tokens.colors.textOnAccent)
        )
        .padding(.leading, videoAppearance.tokens.layout.spacingSm)
        .padding(.trailing, videoAppearance.tokens.layout.spacingXxs)
        .padding(.vertical, videoAppearance.tokens.layout.spacingXxs)
        .frame(minHeight: 32)
        .background(
            Color(
                videoAppearance.tokens.colors.backgroundCoreOverlayDarkStrong
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: videoAppearance.tokens.layout.radiusLg
            )
        )
        .onAppear {
            hasMicrophoneAccess = permissions.hasMicrophonePermission
        }
        .onReceive(permissions.$hasMicrophonePermission) {
            hasMicrophoneAccess = $0
        }
    }

    private var userDisplayName: String {
        streamVideo.user.name.isEmpty
            ? streamVideo.user.id
            : streamVideo.user.name
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
    @Injected(\.videoAppearance) var videoAppearance
    
    @Binding var callSettings: CallSettings
    
    var body: some View {
        HStack(spacing: videoAppearance.tokens.layout.spacingNone) {
            StatelessMicrophoneIconView(
                call: nil,
                callSettings: callSettings,
                size: videoAppearance.tokens.layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(
                        icon: images.micTurnOn,
                        iconStyle: secondaryButtonStyle
                    ),
                    disabled: .init(
                        icon: images.micTurnOff,
                        iconStyle: secondaryButtonStyle
                    )
                )
            ) {
                callSettings = CallSettings(
                    audioOn: !callSettings.audioOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }
            .frame(
                minWidth: videoAppearance.tokens.layout.buttonHitTargetMinWidth,
                minHeight: videoAppearance.tokens.layout.buttonHitTargetMinHeight
            )
            .contentShape(Rectangle())
            .accessibility(
                label: Text(
                    callSettings.audioOn
                        ? L10n.WaitingRoom.Mic.turnOff
                        : L10n.WaitingRoom.Mic.turnOn
                )
            )

            StatelessVideoIconView(
                call: nil,
                callSettings: callSettings,
                size: videoAppearance.tokens.layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(
                        icon: images.videoTurnOn,
                        iconStyle: secondaryButtonStyle
                    ),
                    disabled: .init(
                        icon: images.videoTurnOff,
                        iconStyle: secondaryButtonStyle
                    )
                )
            ) {
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }
            .frame(
                minWidth: videoAppearance.tokens.layout.buttonHitTargetMinWidth,
                minHeight: videoAppearance.tokens.layout.buttonHitTargetMinHeight
            )
            .contentShape(Rectangle())
            .accessibility(
                label: Text(
                    callSettings.videoOn
                        ? L10n.WaitingRoom.Camera.turnOff
                        : L10n.WaitingRoom.Camera.turnOn
                )
            )
        }
    }

    private var secondaryButtonStyle: CallIconStyle {
        CallIconStyle(
            backgroundColor: Color(
                videoAppearance.tokens.colors.buttonSecondaryBackground
            ),
            foregroundColor: Color(
                videoAppearance.tokens.colors.buttonSecondaryText
            ),
            opacity: 1
        )
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
