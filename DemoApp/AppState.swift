//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
class AppState: ObservableObject {
    
    @Published var userState: UserState = .notLoggedIn
    @Published var deeplinkCallId: String?
    @Published var currentUser: User?
    @Published var loading = false
    
    var streamVideo: StreamVideo?
    
    static let shared = AppState()
    
    private init() {}
    
    func connectUser() {
        Task {
            do {
                loading = true
                try await streamVideo?.connect()
                loading = false
            } catch {
                loading = false
            }
        }
    }
}

enum UserState {
    case notLoggedIn
    case loggedIn
}
