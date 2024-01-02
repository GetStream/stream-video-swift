//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI

@MainActor
class DemoCallsViewModel: ObservableObject {    
    @Injected(\.streamVideo) var streamVideo

    @Published var streamEmployees = [StreamEmployee]()
    @Published var favorites = [StreamEmployee]()
    @Published var groupCall = false {
        didSet {
            groupCallParticipants = []
        }
    }
    @Published var groupCallParticipants = [StreamEmployee]()
    
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
    
    func groupSelectionTapped(for employee: StreamEmployee) {
        if groupCallParticipants.contains(employee) {
            groupCallParticipants.removeAll { $0.id == employee.id }
        } else {
            groupCallParticipants.append(employee)
        }
    }
    
    func startCall(with employees: [StreamEmployee]) {
        var memberRequests = [MemberRequest]()
        memberRequests.append(MemberRequest(userId: streamVideo.user.id))
        let members = employees.map { MemberRequest(userId: $0.id) }
        memberRequests.append(contentsOf: members)
        callViewModel.startCall(
            callType: .default,
            callId: UUID().uuidString,
            members: memberRequests,
            ring: true
        )
    }
}
