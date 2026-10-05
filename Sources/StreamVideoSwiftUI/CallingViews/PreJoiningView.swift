//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LobbyView<Factory: ViewFactory, SettingsView: View>: View {

    @StateObject var viewModel: LobbyViewModel
    @StateObject var microphoneChecker = MicrophoneChecker()

    var viewFactory: Factory
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var callSettingsView: (Binding<CallSettings>) -> SettingsView
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
        
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: LobbyViewModel? = nil,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        callSettingsView: @escaping (Binding<CallSettings>) -> SettingsView,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobby: @escaping () -> Void
    ) {
        self.viewFactory = viewFactory
        self.callId = callId
        self.callType = callType
        self.onJoinCallTap = onJoinCallTap
        self.onCloseLobby = onCloseLobby
        self.callSettingsView = callSettingsView
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
            callSettingsView: callSettingsView,
            onJoinCallTap: onJoinCallTap,
            onCloseLobby: onCloseLobby
        )
        .onChange(of: callSettings) { viewModel.didUpdate(callSettings: $0) }
        .onAppear { viewModel.didUpdate(callSettings: callSettings) }
    }
}

struct LobbyContentView<Factory: ViewFactory, SettingsView: View>: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
    @ObservedObject var viewModel: LobbyViewModel
    @ObservedObject var microphoneChecker: MicrophoneChecker

    var viewFactory: Factory
    var callId: String
    var callType: String
    @Binding var callSettings: CallSettings
    var callSettingsView: (Binding<CallSettings>) -> SettingsView
    var onJoinCallTap: () -> Void
    var onCloseLobby: () -> Void
    
    var body: some View {
        VStack(spacing: layout.spacingXs) {
            ZStack {
                HStack(spacing: layout.spacingXs) {
                    Spacer()
                    Button {
                        onCloseLobby()
                    } label: {
                        images.xmark
                            .foregroundColor(textPrimary)
                    }
                }

                VStack(alignment: .center, spacing: layout.spacingXs) {
                    Text(L10n.WaitingRoom.title)
                        .font(fonts.title)
                        .foregroundColor(textPrimary)
                        .bold()

                    Text(L10n.WaitingRoom.subtitle)
                        .font(fonts.body)
                        .foregroundColor(Color(colors.textSecondary))
                }
            }
            .padding(layout.spacingMd)
            .zIndex(1)

            VStack(spacing: layout.spacingXs) {
                CameraCheckView(
                    viewModel: viewModel,
                    microphoneChecker: microphoneChecker,
                    viewFactory: viewFactory,
                    callSettings: callSettings
                )

                if microphoneChecker.isSilent {
                    Text(L10n.WaitingRoom.Mic.notWorking)
                        .font(fonts.caption1)
                        .foregroundColor(textPrimary)
                }

                callSettingsView($callSettings)

                JoinCallView(
                    viewFactory: viewFactory,
                    callId: callId,
                    callType: callType,
                    callParticipants: viewModel.participants,
                    onJoinCallTap: onJoinCallTap
                )
            }
            .padding(layout.spacingMd)
        }
        .background(
            Color(colors.backgroundCoreApp)
                .edgesIgnoringSafeArea(.all)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { viewModel.startCamera(front: true) }
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
        }
    }

    private var textPrimary: Color { Color(colors.textPrimary) }
}

@available(iOS 14.0, *)
extension LobbyView where SettingsView == CallSettingsView {
    init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: LobbyViewModel? = nil,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobby: @escaping () -> Void
    ) {
        self.init(
            viewFactory: viewFactory,
            viewModel: viewModel,
            callId: callId,
            callType: callType,
            callSettings: callSettings,
            callSettingsView: { CallSettingsView(callSettings: $0) },
            onJoinCallTap: onJoinCallTap,
            onCloseLobby: onCloseLobby
        )
    }
}

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout
    
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
                                Color(colors.backgroundCoreSurfaceDefault)
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
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
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
                RoundedRectangle(cornerRadius: layout.radiusXl)
            )
        }
    }

    private var avatarSize: CGFloat { layout.buttonVisualHeightLg }
}

struct JoinCallView<Factory: ViewFactory>: View {

    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    var viewFactory: Factory
    var callId: String
    var callType: String
    var callParticipants: [User]
    var onJoinCallTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: layout.spacingMd) {
            Text(waitingRoomDescription)
                .font(fonts.headline)
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
            .frame(height: layout.buttonVisualHeightLg)
            .background(Color(colors.buttonPrimaryBackground))
            .cornerRadius(layout.radiusXl)
            .foregroundColor(Color(colors.buttonPrimaryTextOnAccent))
        }
        .padding(layout.spacingMd)
        .background(Color(colors.backgroundCoreSurfaceDefault))
        .cornerRadius(layout.radiusXl)
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
    
    @Injected(\.images) private var images
    @Injected(\.layout) private var layout
    
    @Binding var callSettings: CallSettings
    
    var body: some View {
        HStack(spacing: layout.spacing2xl) {
            StatelessMicrophoneIconView(
                call: nil,
                callSettings: callSettings,
                size: layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(icon: images.micTurnOn, iconStyle: .secondary),
                    disabled: .init(icon: images.micTurnOff, iconStyle: .disabled)
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
                size: layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(icon: images.videoTurnOn, iconStyle: .secondary),
                    disabled: .init(icon: images.videoTurnOff, iconStyle: .disabled)
                )
            ) {
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }
        }
        .padding(layout.spacingMd)
    }
}

@available(iOS 14.0, *)
struct ParticipantsInCallView<Factory: ViewFactory>: View {

    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

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
            LazyHStack(spacing: layout.spacingXs) {
                ForEach(participantsInCall) { participant in
                    VStack(spacing: layout.spacingXs) {
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
                            .font(fonts.caption1)
                    }
                    .frame(width: viewSize, height: viewSize)
                }
            }
        }
        .frame(height: viewSize)
    }

    private var avatarSize: CGFloat { layout.buttonVisualHeightMd }

    private var viewSize: CGFloat { avatarSize + layout.spacingXl }
}
