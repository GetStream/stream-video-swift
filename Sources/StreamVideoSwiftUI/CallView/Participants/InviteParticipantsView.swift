//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct InviteParticipantsView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    @StateObject var viewModel: InviteParticipantsViewModel
    
    @Binding var inviteParticipantsShown: Bool
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        inviteParticipantsShown: Binding<Bool>,
        currentParticipants: [CallParticipant],
        call: Call?
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(
            wrappedValue: InviteParticipantsViewModel(
                currentParticipants: currentParticipants,
                call: call
            )
        )
        _inviteParticipantsShown = inviteParticipantsShown
    }

    init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: InviteParticipantsViewModel,
        inviteParticipantsShown: Binding<Bool>
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel)
        _inviteParticipantsShown = inviteParticipantsShown
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText)
                .padding(.vertical, !viewModel.selectedUsers.isEmpty ? 0 : layout.spacingMd)

            ScrollView(.horizontal) {
                HStack(spacing: layout.spacingMd) {
                    ForEach(viewModel.selectedUsers) { user in
                        SelectedParticipantView(viewFactory: viewFactory, user: user) { user in
                            viewModel.userTapped(user)
                        }
                    }
                }
                .padding(.all, !viewModel.selectedUsers.isEmpty ? layout.spacingMd : 0)
            }

            UsersHeaderView()
            List(viewModel.filteredUsers) { user in
                Button {
                    withAnimation {
                        viewModel.userTapped(user)
                    }
                } label: {
                    VideoUserView(
                        viewFactory: viewFactory,
                        user: user,
                        isSelected: viewModel.isSelected(user: user)
                    )
                }
                .onAppear {
                    viewModel.onUserAppear(user: user)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(L10n.Call.Participants.add)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    inviteParticipantsShown = false
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.inviteUsersTapped()
                } label: {
                    Text(L10n.Call.Participants.invite)
                        .bold()
                }
                .disabled(viewModel.selectedUsers.isEmpty)
            }
        })
        .navigationBarBackButtonHidden(true)
    }
}

struct UsersHeaderView: View {

    var title = L10n.Call.Participants.onPlatform

    var body: some View {
        HStack {
            Text(title)
                .padding(.horizontal, layout.spacingMd)
                .padding(.vertical, layout.spacingXxxs)
                .font(fonts.body)
                .foregroundColor(Color(colors.textSecondary))

            Spacer()
        }
        .background(Color(colors.backgroundCoreSurfaceDefault))
    }
}

struct VideoUserView<Factory: ViewFactory>: View {

    @Injected(\.videoAppearance) var videoAppearance

    private let avatarSize: CGFloat = 56

    var viewFactory: Factory
    var user: User
    var isSelected: Bool

    init(
        viewFactory: Factory,
        user: User,
        isSelected: Bool
    ) {
        self.viewFactory = viewFactory
        self.user = user
        self.isSelected = isSelected
    }

    var body: some View {
        HStack {
            viewFactory.makeUserAvatar(user, with: .init(size: avatarSize))

            Text(user.name)
                .lineLimit(1)
                .font(fonts.bodyBold)

            Spacer()

            if isSelected {
                selectedCheckmark
            }
        }
    }

    @ViewBuilder
    private var selectedCheckmark: some View {
        if #available(iOS 15.0, *) {
            videoAppearance.images.checkmarkCircleFill
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(colors.textOnAccent), Color(colors.accentPrimary))
        } else {
            videoAppearance.images.checkmarkCircleFill
                .foregroundColor(Color(colors.accentPrimary))
        }
    }
}
