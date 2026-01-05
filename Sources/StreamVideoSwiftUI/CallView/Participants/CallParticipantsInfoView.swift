//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct CallParticipantsInfoView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @StateObject var viewModel: CallParticipantsInfoViewModel
    @ObservedObject var callViewModel: CallViewModel

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callViewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.callViewModel = callViewModel
        _viewModel = StateObject(
            wrappedValue: CallParticipantsInfoViewModel(
                call: callViewModel.call
            )
        )
    }
    
    public var body: some View {
        CallParticipantsView(
            viewFactory: viewFactory,
            viewModel: viewModel,
            callViewModel: callViewModel
        )
    }
}

@available(iOS 14.0, *)
struct CallParticipantsView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @ObservedObject var viewModel: CallParticipantsInfoViewModel
    @ObservedObject var callViewModel: CallViewModel

    init(
        viewFactory: Factory,
        viewModel: CallParticipantsInfoViewModel,
        callViewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.callViewModel = callViewModel
    }

    var body: some View {
        CallParticipantsViewContainer(
            viewFactory: viewFactory,
            viewModel: viewModel,
            participants: participants,
            call: callViewModel.call,
            blockedUsers: callViewModel.blockedUsers,
            callSettings: callViewModel.callSettings,
            inviteParticipantsShown: $viewModel.inviteParticipantsShown,
            inviteTapped: {
                viewModel.inviteParticipantsShown = true
            },
            muteTapped: {
                callViewModel.toggleMicrophoneEnabled()
            },
            closeTapped: {
                callViewModel.participantsShown = false
            }
        )
    }
    
    private var participants: [CallParticipant] {
        callViewModel.callParticipants
            .map(\.value)
            .sorted(by: { $0.name < $1.name })
    }
}

@available(iOS 14.0, *)
struct CallParticipantsViewContainer<Factory: ViewFactory>: View {

    @ObservedObject var viewModel: CallParticipantsInfoViewModel
    
    @Injected(\.colors) var colors
    @Injected(\.images) var images

    var viewFactory: Factory
    var participants: [CallParticipant]
    var call: Call?
    var blockedUsers: [User]
    var callSettings: CallSettings
    @Binding var inviteParticipantsShown: Bool
    var inviteTapped: () -> Void
    var muteTapped: () -> Void
    var closeTapped: () -> Void
    
    @State private var listHeight: CGFloat

    init(
        viewFactory: Factory,
        viewModel: CallParticipantsInfoViewModel,
        participants: [CallParticipant],
        call: Call? = nil,
        blockedUsers: [User],
        callSettings: CallSettings,
        inviteParticipantsShown: Binding<Bool>,
        inviteTapped: @escaping () -> Void,
        muteTapped: @escaping () -> Void,
        closeTapped: @escaping () -> Void,
        listHeight: CGFloat = 0
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.participants = participants
        self.call = call
        self.blockedUsers = blockedUsers
        self.callSettings = callSettings
        _inviteParticipantsShown = .init(projectedValue: inviteParticipantsShown)
        self.inviteTapped = inviteTapped
        self.muteTapped = muteTapped
        self.closeTapped = closeTapped
        _listHeight = .init(initialValue: listHeight)
    }

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(participants) { participant in
                            CallParticipantView(
                                viewFactory: viewFactory,
                                participant: participant,
                                menuActions: viewModel.menuActions(for: participant)
                            )
                            .id(participant.renderingId)
                        }
                        if !blockedUsers.isEmpty {
                            BlockedUsersView(
                                blockedUsers: blockedUsers,
                                unblockActions: viewModel.unblockActions(for:)
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 16) {
                    if viewModel.inviteParticipantsButtonShown {
                        ParticipantsButton(title: L10n.Call.Participants.invite, onTapped: inviteTapped)
                    }

                    ParticipantsButton(
                        title: callSettings.audioOn ? L10n.Call.Participants.muteme : L10n.Call.Participants.unmuteme,
                        primaryStyle: false,
                        onTapped: muteTapped
                    )
                }
                .padding()

                NavigationLink(isActive: $inviteParticipantsShown) {
                    InviteParticipantsView(
                        viewFactory: viewFactory,
                        inviteParticipantsShown: $inviteParticipantsShown,
                        currentParticipants: participants,
                        call: call
                    )
                } label: {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ModalButton(image: images.xmark, action: closeTapped)
                        .accessibility(identifier: "Close")
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .accessibility(identifier: "participantsScrollView")
            .streamAccessibility(value: "\(participants.count)")
        }
        .navigationViewStyle(.stack)
    }

    private var navigationTitle: String {
        let participantsCount = call?.state.participants.count ?? 0
        if participantsCount > 1 {
            return "\(L10n.Call.Participants.title) (\(participantsCount))"
        } else {
            return L10n.Call.Participants.title
        }
    }
}

struct ParticipantsButton: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    
    private let cornerRadius: CGFloat = 24
    
    var title: String
    var primaryStyle: Bool = true
    var onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Text(title)
                .font(fonts.headline)
                .bold()
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(
                    primaryStyle ? colors.textInverted : colors.secondaryButton
                )
                .background(primaryStyle ? colors.tintColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(primaryStyle ? colors.tintColor : colors.secondaryButton, lineWidth: 1)
                )
                .cornerRadius(cornerRadius)
        }
    }
}

struct BlockedUsersView: View {
    
    var blockedUsers: [User]
    var unblockActions: @MainActor (User) -> [CallParticipantMenuAction]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(L10n.Call.Participants.blocked)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)
                ForEach(blockedUsers) { blockedUser in
                    Text(blockedUser.id)
                        .contextMenu {
                            ForEach(unblockActions(blockedUser)) { menuAction in
                                Button {
                                    menuAction.action(blockedUser.id)
                                } label: {
                                    HStack {
                                        Image(systemName: menuAction.iconName)
                                        Text(menuAction.title)
                                        Spacer()
                                    }
                                }
                            }
                        }
                }
            }
            Spacer()
        }
    }
}

struct CallParticipantView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
    private let imageSize: CGFloat = 48

    var viewFactory: Factory
    var participant: CallParticipant
    var menuActions: [CallParticipantMenuAction]

    init(
        viewFactory: Factory,
        participant: CallParticipant,
        menuActions: [CallParticipantMenuAction]
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.menuActions = menuActions
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                viewFactory.makeUserAvatar(
                    participant.user,
                    with: .init(size: imageSize) {
                        AnyView(
                            CircledTitleView(
                                title: participant.name.isEmpty
                                    ? participant.id
                                    : String(participant.name.uppercased().first!),
                                size: imageSize
                            )
                        )
                    }
                )
                .overlay(TopRightView { OnlineIndicatorView(indicatorSize: imageSize * 0.3) })

                Text(participant.name)
                    .font(fonts.bodyBold)
                Spacer()
                (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                    .foregroundColor(participant.hasAudio ? colors.text : colors.inactiveCallControl)

                (participant.hasVideo ? images.videoTurnOn : images.videoTurnOff)
                    .foregroundColor(participant.hasVideo ? colors.text : colors.inactiveCallControl)
            }
            .padding(.all, 4)

            Divider()
        }
        .contextMenu {
            ForEach(menuActions) { menuAction in
                Button {
                    menuAction.action(participant.userId)
                } label: {
                    HStack {
                        Image(systemName: menuAction.iconName)
                        Text(menuAction.title)
                        Spacer()
                    }
                }
            }
        }
    }
}

extension CallParticipant {
    
    var renderingId: String {
        "\(trackLookupPrefix ?? id)-\(hasAudio)-\(shouldDisplayTrack)"
    }
}
