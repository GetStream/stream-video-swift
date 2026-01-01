//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    
    @Published var selectedUsers = [User]()
    @Published var allUsers = [User]()
    
    private let limit = 15
    private var offset = 0
    
    private var loading = false
    
    private var currentParticipantIds: [String]
    private var call: Call?
    
    var filteredUsers: [User] {
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
        
    init(currentParticipants: [CallParticipant], call: Call?) {
        currentParticipantIds = currentParticipants.map(\.userId)
        self.call = call
        loadNextUsers()
    }
    
    func inviteUsersTapped() {
        guard let call else { return }
        Task {
            do {
                let result = try await call.addMembers(ids: selectedUsers.map(\.id))
                log.debug("added call members \(result)")
                withAnimation {
                    allUsers = allUsers.filter { !selectedUsers.contains($0) }
                    selectedUsers = []
                }
            } catch {
                log.error(error.localizedDescription, error: error)
            }
        }
    }
    
    func userTapped(_ user: User) {
        if selectedUsers.contains(user) {
            selectedUsers.removeAll { current in
                user.id == current.id
            }
        } else {
            selectedUsers.append(user)
        }
    }
    
    func onUserAppear(user: User) {
        guard let index = allUsers.firstIndex(of: user),
              index < allUsers.count - 10 else {
            return
        }
        loadNextUsers()
    }
    
    func isSelected(user: User) -> Bool {
        selectedUsers.contains(user)
    }
    
    private func loadNextUsers() {
        if loading {
            return
        }

        guard let userListProvider = utils.userListProvider else {
            return
        }

        loading = true
        Task {
            do {
                let newUsers = try await userListProvider.loadNextUsers(
                    pagination: Pagination(pageSize: limit, offset: offset)
                )
                var temp = [User]()
                for user in allUsers {
                    temp.append(user)
                }
                temp.append(contentsOf: newUsers)
                allUsers = temp
                offset = allUsers.count
                loading = false
            } catch {
                log.error(error)
            }
        }
    }
}
