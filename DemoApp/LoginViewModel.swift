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
    
    func login(user: User, completion: @escaping (UserCredentials) -> ()) {
        Task {
            let token = try await self.tokenService.fetchToken(for: user.id)
            let credentials = UserCredentials(userInfo: user, token: token)
            UnsecureUserRepository.shared.save(user: credentials)
            AppState.shared.currentUser = user
            AppState.shared.userState = .loggedIn
            // Perform login
            completion(credentials)
        }
    }
    
}
