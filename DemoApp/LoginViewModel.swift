//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

@MainActor
class LoginViewModel: ObservableObject {
        
    @Published var loading = false
    
    @Published var users = User.builtInUsers
    
    let tokenService = TokenService.shared
    
    func login(user: User, callId: String = "", completion: @escaping (UserCredentials) -> ()) {
        Task {
            let token = try await self.tokenService.fetchToken(for: user.id, callIds: [callId])
            let credentials = UserCredentials(userInfo: user, token: token)
            UnsecureUserRepository.shared.save(user: credentials)
            AppState.shared.currentUser = user
            AppState.shared.userState = .loggedIn
            // Perform login
            completion(credentials)
        }
    }

    func joinCallAnonymously(callId: String, completion: @escaping (UserCredentials) -> ()) {
        Task {
            let token = try await self.tokenService.fetchToken(for: User.anonymous.id, callIds: ["default:\(callId)"])
            let credentials = UserCredentials(userInfo: User.anonymous, token: token)
            AppState.shared.currentUser = .anonymous
            AppState.shared.userState = .loggedIn
            // Perform login
            completion(credentials)
            AppState.shared.activeAnonymousCallId = callId
        }
    }
}
