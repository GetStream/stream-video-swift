//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
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
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.videoAppearance) var videoAppearance
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker

    var viewFactory: Factory
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
    
    var body: some View {
        VStack(spacing: tokens.layout.spacingXs) {
            ZStack {
                HStack(spacing: tokens.layout.spacingXs) {
                    Spacer()
                    Button {
                        onCloseLobby()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(textPrimary)
                    }
                }

                VStack(alignment: .center, spacing: tokens.layout.spacingXs) {
                    Text(L10n.WaitingRoom.title)
                        .font(tokens.fonts.title)
                        .foregroundColor(textPrimary)
                        .bold()

                    Text(L10n.WaitingRoom.subtitle)
                        .font(tokens.fonts.body)
                        .foregroundColor(Color(tokens.colors.textSecondary))
                }
            }
            .padding(tokens.layout.spacingMd)
            .zIndex(1)

            VStack(spacing: tokens.layout.spacingXs) {
                CameraCheckView(
                    viewModel: viewModel,
                    microphoneChecker: microphoneChecker,
                    viewFactory: viewFactory,
                    callSettings: callSettings
                )

                if microphoneChecker.isSilent {
                    Text(L10n.WaitingRoom.Mic.notWorking)
                        .font(tokens.fonts.caption1)
                        .foregroundColor(textPrimary)
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
            .padding(tokens.layout.spacingMd)
        }
        .background(
            Color(tokens.colors.backgroundCoreApp)
                .edgesIgnoringSafeArea(.all)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { viewModel.startCamera(front: true) }
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private var textPrimary: Color { Color(tokens.colors.textPrimary) }
}

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
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
                        .streamAccessibility(value: "1")
                } else {
                    ZStack {
                        Rectangle()
                            .fill(
                                Color(tokens.colors.backgroundCoreSurfaceDefault)
                            )

                        viewFactory.makeUserAvatar(
                            streamVideo.user,
                            with: .init(size: avatarSize)
                        )
                        .accessibility(identifier: "cameraCheckView")
                        .streamAccessibility(value: "0")
                    }
                    .opacity(callSettings.videoOn ? 0 : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(
                VStack(spacing: tokens.layout.spacingNone) {
                    Spacer()
                    HStack(spacing: tokens.layout.spacingNone) {
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
            .clipShape(
                RoundedRectangle(cornerRadius: tokens.layout.radiusXl)
            )
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private var avatarSize: CGFloat { tokens.layout.buttonVisualHeightLg }
}

struct JoinCallView<Factory: ViewFactory>: View {

    @Injected(\.videoAppearance) var videoAppearance

    var viewFactory: Factory
    var callId: String
    var callType: String
    var callParticipants: [User]
    var onJoinCallTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: tokens.layout.spacingMd) {
            Text(waitingRoomDescription)
                .font(tokens.fonts.headline)
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
            .frame(height: tokens.layout.buttonVisualHeightLg)
            .background(Color(tokens.colors.buttonPrimaryBackground))
            .cornerRadius(tokens.layout.radiusXl)
            .foregroundColor(Color(tokens.colors.buttonPrimaryTextOnAccent))
        }
        .padding(tokens.layout.spacingMd)
        .background(Color(tokens.colors.backgroundCoreSurfaceDefault))
        .cornerRadius(tokens.layout.radiusXl)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
    
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
        HStack(spacing: tokens.layout.spacing2xl) {
            StatelessMicrophoneIconView(
                call: nil,
                callSettings: callSettings,
                size: tokens.layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(icon: images.micTurnOn, iconStyle: secondaryButtonStyle),
                    disabled: .init(icon: images.micTurnOff, iconStyle: secondaryButtonStyle)
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
                size: tokens.layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(icon: images.videoTurnOn, iconStyle: secondaryButtonStyle),
                    disabled: .init(icon: images.videoTurnOff, iconStyle: secondaryButtonStyle)
                )
            ) {
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }
        }
        .padding(tokens.layout.spacingMd)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private var secondaryButtonStyle: CallIconStyle {
        CallIconStyle(
            backgroundColor: Color(tokens.colors.buttonSecondaryBackground),
            foregroundColor: Color(tokens.colors.buttonSecondaryText),
            opacity: 1
        )
    }
}

@available(iOS 14.0, *)
struct ParticipantsInCallView<Factory: ViewFactory>: View {

    @Injected(\.videoAppearance) var videoAppearance

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
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: tokens.layout.spacingXs) {
                ForEach(participantsInCall) { participant in
                    VStack(spacing: tokens.layout.spacingXs) {
                        viewFactory.makeUserAvatar(
                            participant.user,
                            with: .init(size: avatarSize) {
                                AnyView(
                                    CircledTitleView(
                                        title: participant.user.name.isEmpty ? participant.user
                                            .id : String(participant.user.name.uppercased().first!),
                                        size: avatarSize
                                    )
                                )
                            }
                        )

                        Text(participant.user.name)
                            .font(tokens.fonts.caption1)
                    }
                    .frame(width: viewSize, height: viewSize)
                }
            }
        }
        .frame(height: viewSize)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private var avatarSize: CGFloat { tokens.layout.buttonVisualHeightMd }

    private var viewSize: CGFloat { avatarSize + tokens.layout.spacingXl }
}
