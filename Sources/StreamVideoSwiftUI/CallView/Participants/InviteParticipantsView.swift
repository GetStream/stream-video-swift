//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
struct InviteParticipantsView: View {
    
    @StateObject var viewModel: InviteParticipantsViewModel
    
    @Binding var inviteParticipantsShown: Bool
    
    init(
        inviteParticipantsShown: Binding<Bool>,
        currentParticipants: [CallParticipant]
    ) {
        _viewModel = StateObject(
            wrappedValue: InviteParticipantsViewModel(
                currentParticipants: currentParticipants
            )
        )
        _inviteParticipantsShown = inviteParticipantsShown
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText)
                .padding(.vertical, !viewModel.selectedUsers.isEmpty ? 0 : 16)
            
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(viewModel.selectedUsers) { user in
                        SelectedParticipantView(user: user) { user in
                            viewModel.userTapped(user)
                        }
                    }
                }
                .padding(.all, !viewModel.selectedUsers.isEmpty ? 16 : 0)
            }

            UsersHeaderView()
            List(viewModel.filteredUsers) { user in
                Button {
                    withAnimation {
                        viewModel.userTapped(user)
                    }
                } label: {
                    VideoUserView(
                        user: user,
                        onlineText: viewModel.onlineInfo(for: user),
                        isSelected: viewModel.isSelected(user: user)
                    )
                }
                .onAppear {
                    viewModel.onUserAppear(user: user)
                }
            }
            .listStyle(.plain)
        }
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    inviteParticipantsShown = false
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(L10n.Call.Participants.add)
                    .bold()
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
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    var title = L10n.Call.Participants.onPlatform
    
    var body: some View {
        HStack {
            Text(title)
                .padding(.horizontal)
                .padding(.vertical, 2)
                .font(fonts.body)
                .foregroundColor(Color(colors.textLowEmphasis))
            
            Spacer()
        }
        .background(Color(colors.background1))
    }
}

struct VideoUserView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    private let avatarSize: CGFloat = 56
    
    var user: User
    var onlineText: String
    var isSelected: Bool
    
    var body: some View {
        HStack {
            if #available(iOS 14.0, *) {
                LazyImage(url: user.imageURL)
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .lineLimit(1)
                    .font(fonts.bodyBold)
                Text(onlineText)
                    .font(fonts.footnote)
                    .foregroundColor(Color(colors.textLowEmphasis))
            }
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(colors.tintColor)
            }
        }
    }
}
