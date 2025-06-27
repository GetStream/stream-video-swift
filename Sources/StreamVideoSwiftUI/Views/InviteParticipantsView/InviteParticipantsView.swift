//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    
    public var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText)
                .padding(.vertical, !viewModel.selectedUsers.isEmpty ? 0 : 16)
            
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(viewModel.selectedUsers) { user in
                        SelectedParticipantView(viewFactory: viewFactory, user: user) { user in
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
