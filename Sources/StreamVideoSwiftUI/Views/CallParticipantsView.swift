//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
struct CallParticipantsView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @ObservedObject var viewModel: CallParticipantsInfoViewModel

    init(
        viewFactory: Factory,
        viewModel: CallParticipantsInfoViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    var body: some View {
        CallParticipantsViewContainer(
            viewFactory: viewFactory,
            viewModel: viewModel,
            participants: viewModel.participants,
            call: viewModel.callViewModel.call,
            blockedUsers: viewModel.callViewModel.blockedUsers,
            callSettings: viewModel.callViewModel.callSettings,
            inviteParticipantsShown: $viewModel.inviteParticipantsShown,
            inviteTapped: {
                viewModel.inviteParticipantsShown = true
            },
            muteTapped: {
                viewModel.callViewModel.toggleMicrophoneEnabled()
            },
            closeTapped: {
                viewModel.callViewModel.participantsShown = false
            }
        )
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
                                viewModel: viewModel,
                                blockedUsers: blockedUsers
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
