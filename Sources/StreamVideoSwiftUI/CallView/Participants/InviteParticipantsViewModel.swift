//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

@MainActor
class InviteParticipantsViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.utils) var utils
    
    @Published var searchText = ""
    
    @Published var selectedUsers = [UserInfo]()
    @Published var allUsers = [UserInfo]()
    
    private let limit = 15
    private var offset = 0
    
    private var loading = false
    
    private var currentParticipantIds: [String]
    
    var filteredUsers: [UserInfo] {
        let displayUsers = allUsers.filter { !currentParticipantIds.contains($0.id) }
        if searchText.isEmpty {
            return displayUsers
        } else {
            return displayUsers.filter { user in
                let name = (user.name).lowercased()
                return name.contains(searchText.lowercased())
            }
        }
    }
        
    init(currentParticipants: [CallParticipant]) {
        currentParticipantIds = currentParticipants.map(\.id)
        loadNextUsers()
    }
    
    func inviteUsersTapped() {
        guard let controller = streamVideo.currentCallController else { return }
        Task {
            try await controller.addMembersToCall(ids: selectedUsers.map(\.id))
            withAnimation {
                allUsers = allUsers.filter { !selectedUsers.contains($0) }
                selectedUsers = []
            }
        }
    }
    
    func userTapped(_ user: UserInfo) {
        if selectedUsers.contains(user) {
            selectedUsers.removeAll { current in
                user.id == current.id
            }
        } else {
            selectedUsers.append(user)
        }
    }
    
    func onUserAppear(user: UserInfo) {
        guard let index = allUsers.firstIndex(of: user),
              index < allUsers.count - 10 else {
            return
        }
        loadNextUsers()
    }
    
    func isSelected(user: UserInfo) -> Bool {
        selectedUsers.contains(user)
    }
    
    func onlineInfo(for user: UserInfo) -> String {
        // TODO: provide implementation
        ""
    }
    
    private func loadNextUsers() {
        if loading {
            return
        }
        
        loading = true
        Task {
            let newUsers = try await utils.userListProvider.loadNextUsers(
                pagination: Pagination(pageSize: limit, offset: offset)
            )
            var temp = [UserInfo]()
            for user in allUsers {
                temp.append(user)
            }
            temp.append(contentsOf: newUsers)
            allUsers = temp
            offset = allUsers.count
            loading = false
        }
    }
}
