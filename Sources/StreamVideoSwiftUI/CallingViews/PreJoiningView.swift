//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct LobbyView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var viewModel: LobbyViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callViewModel: CallViewModel,
        callId: String,
        callType: String,
        callSettings: Binding<CallSettings>,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobby: @escaping () -> Void
    ) {
        self.viewFactory = viewFactory
        viewModel = LobbyViewModel(
            callType: callType,
            callId: callId,
            callViewModel: callViewModel,
            onJoinCallTap: onJoinCallTap,
            onCloseLobbyTap: onCloseLobby
        )
    }

    public var body: some View {
        VStack {
            headerView
            middleView
            footerView
        }
        .padding()
        .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            viewModel.stopCamera()
            viewModel.cleanUp()
        }
    }

    @ViewBuilder
    var headerView: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    viewModel.didTapClose()
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
    }

    @ViewBuilder
    var middleView: some View {
        CameraCheckView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )

        SilentMicrophoneIndicator(viewModel: viewModel)

        CallSettingsView(viewModel: viewModel)
    }

    @ViewBuilder
    var footerView: some View {
        JoinCallView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )
        .layoutPriority(2)
    }
}

struct CameraCheckView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo

    var viewFactory: Factory
    var viewModel: LobbyViewModel

    init(
        viewFactory: Factory,
        viewModel: LobbyViewModel
    ) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
    }

    var body: some View {
        contentView
            .overlay(overlayView)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    var contentView: some View {
        CameraFeedPreviewView(viewFactory: viewFactory, viewModel: viewModel)
    }

    @ViewBuilder
    var overlayView: some View {
        BottomView {
            HStack {
                MicrophoneCheckView(viewModel: viewModel, isPinned: false)
                    .accessibility(identifier: "microphoneCheckView")
                Spacer()
            }
        }
    }
}

struct JoinCallView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewFactory: Factory
    var viewModel: LobbyViewModel

    @State var participants: [User]
    var participantsPublisher: AnyPublisher<[User], Never>

    init(
        viewFactory: Factory,
        viewModel: LobbyViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel

        participants = viewModel.participants
        participantsPublisher = viewModel.$participants.eraseToAnyPublisher()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(waitingRoomDescription)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(identifier: "callParticipantsCount")
                .streamAccessibility(value: "\(participants.count)")

            if #available(iOS 14, *) {
                if !participants.isEmpty {
                    ParticipantsInCallView(
                        viewFactory: viewFactory,
                        callParticipants: participants
                    )
                }
            }

            Button {
                viewModel.didTapJoin()
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
        .onReceive(participantsPublisher) { participants = $0 }
    }

    private var waitingRoomDescription: String {
        "\(L10n.WaitingRoom.description) \(L10n.WaitingRoom.numberOfParticipants(participants.count))"
    }

    private var otherParticipantsCount: Int {
        let count = participants.count - 1
        if count > 0 {
            return count
        } else {
            return 0
        }
    }
}

struct CallSettingsView: View {

    @Injected(\.images) var images

    var viewModel: LobbyViewModel
    var iconSize: CGFloat

    @State var audioOn: Bool
    var audioOnPublisher: AnyPublisher<Bool, Never>

    @State var videoOn: Bool
    var videoOnPublisher: AnyPublisher<Bool, Never>

    init(
        viewModel: LobbyViewModel,
        iconSize: CGFloat = 50
    ) {
        self.viewModel = viewModel
        self.iconSize = iconSize

        audioOn = viewModel.audioOn
        audioOnPublisher = viewModel.$audioOn.eraseToAnyPublisher()
        videoOn = viewModel.videoOn
        videoOnPublisher = viewModel.$videoOn.eraseToAnyPublisher()
    }

    var body: some View {
        HStack(spacing: 32) {
            toggleMicrophoneButton
            toggleCameraButton
        }
        .padding()
        .onReceive(audioOnPublisher) { audioOn = $0 }
        .onReceive(videoOnPublisher) { videoOn = $0 }
    }

    @ViewBuilder
    var toggleMicrophoneButton: some View {
        Button {
            viewModel.toggleMicrophoneEnabled()
        } label: {
            CallIconView(
                icon: audioOn ? images.micTurnOn : images.micTurnOff,
                size: iconSize,
                iconStyle: audioOn ? .primary : .transparent
            )
            .accessibility(identifier: "microphoneToggle")
            .streamAccessibility(value: audioOn ? "1" : "0")
        }
    }

    @ViewBuilder
    var toggleCameraButton: some View {
        Button {
            viewModel.toggleCameraEnabled()
        } label: {
            CallIconView(
                icon: videoOn ? images.videoTurnOn : images.videoTurnOff,
                size: iconSize,
                iconStyle: videoOn ? .primary : .transparent
            )
            .accessibility(identifier: "cameraToggle")
            .streamAccessibility(value: videoOn ? "1" : "0")
        }
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
