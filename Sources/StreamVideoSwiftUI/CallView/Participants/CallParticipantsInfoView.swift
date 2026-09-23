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

    @Injected(\.videoAppearance) var videoAppearance

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
                    .padding(.horizontal, layout.spacingMd)
                }

                HStack(spacing: layout.spacingMd) {
                    if viewModel.inviteParticipantsButtonShown {
                        ParticipantsButton(title: L10n.Call.Participants.invite, onTapped: inviteTapped)
                    }

                    ParticipantsButton(
                        title: callSettings.audioOn ? L10n.Call.Participants.muteme : L10n.Call.Participants.unmuteme,
                        primaryStyle: false,
                        onTapped: muteTapped
                    )
                }
                .padding(layout.spacingMd)

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        closeTapped()
                    } label: {
                        videoAppearance.images.xmark
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .padding(layout.spacingXxs)
                            .frame(width: layout.iconSizeMd, height: layout.iconSizeMd)
                            .foregroundColor(Color(colors.textPrimary))
                    }
                    .accessibility(identifier: "Close")
                }

                ToolbarItem(placement: .principal) {
                    Text(navigationTitle)
                        .font(fonts.headline)
                        .foregroundColor(Color(colors.textPrimary))
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(colors.backgroundCoreElevation1).edgesIgnoringSafeArea(.all))
            .modifier(ParticipantsSheetBackgroundModifier(color: colors.backgroundCoreElevation1))
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

struct ParticipantsSheetBackgroundModifier: ViewModifier {

    var color: UIColor

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .toolbarBackground(Color(color), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .presentationBackground(Color(color))
        } else if #available(iOS 16.0, *) {
            content
                .toolbarBackground(Color(color), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }
}

struct ParticipantsButton: View {

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
                .padding(.vertical, layout.spacingSm)
                .frame(maxWidth: .infinity)
                .foregroundColor(
                    primaryStyle
                        ? Color(colors.buttonPrimaryTextOnAccent)
                        : Color(colors.buttonSecondaryText)
                )
                .background(
                    primaryStyle
                        ? Color(colors.buttonPrimaryBackground)
                        : Color(colors.buttonSecondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: layout.radius3xl)
                        .stroke(
                            primaryStyle
                                ? Color(colors.buttonPrimaryBackground)
                                : Color(colors.buttonSecondaryBorder),
                            lineWidth: 1
                        )
                )
                .cornerRadius(layout.radius3xl)
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
                    .font(fonts.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, layout.spacingXs)
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

    @Injected(\.videoAppearance) var videoAppearance

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
        VStack(spacing: layout.spacingXxs) {
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
                (
                    participant.hasAudio
                        ? videoAppearance.images.micTurnOn
                        : videoAppearance.images.micTurnOff
                )
                .foregroundColor(
                    participant.hasAudio
                        ? Color(colors.textPrimary)
                        : Color(colors.accentError)
                )

                (
                    participant.hasVideo
                        ? videoAppearance.images.videoTurnOn
                        : videoAppearance.images.videoTurnOff
                )
                .foregroundColor(
                    participant.hasVideo
                        ? Color(colors.textPrimary)
                        : Color(colors.accentError)
                )
            }
            .padding(.all, layout.spacingXxs)

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
