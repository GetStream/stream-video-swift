//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI

@MainActor
class DemoCallsViewModel: ObservableObject {    
    @Injected(\.streamVideo) var streamVideo

    @Published var streamEmployees = [StreamEmployee]()
    @Published var favorites = [StreamEmployee]()
    
    let callViewModel: CallViewModel
    
    private let userRepository = AppState.shared.unsecureRepository
    
    init(callViewModel: CallViewModel) {
        self.callViewModel = callViewModel
    }
    
    func loadEmployees() {
        Task {
            let allEmployees = try await GoogleHelper.loadUsers()
            self.streamEmployees = allEmployees.filter { $0.isFavorite == false }
            self.favorites = allEmployees.filter { $0.isFavorite }
        }
    }
        
    func favoriteTapped(for employee: StreamEmployee) {
        if favorites.contains(employee) {
            favorites.removeAll { $0.id == employee.id }
            var updated = employee
            updated.isFavorite = false
            streamEmployees.insert(updated, at: 0)
            userRepository.removeFromFavorites(userId: employee.id)
        } else {
            streamEmployees.removeAll { $0.id == employee.id }
            var updated = employee
            updated.isFavorite = true
            favorites.insert(updated, at: 0)
            userRepository.addToFavorites(userId: employee.id)
        }
    }
    
    func startCall(with employee: StreamEmployee) {
        callViewModel.startCall(
            callType: .default,
            callId: UUID().uuidString,
            members: [
                MemberRequest(userId: employee.id),
                MemberRequest(userId: streamVideo.user.id)
            ],
            ring: true
        )
    }
}
