//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

@MainActor
class LoginViewModel: ObservableObject {

    @Published var loading = false

    @Published var userCredentials = UserCredentials.builtInUsers

    func login(user: UserCredentials, completion: (UserCredentials) -> ()) {
        UnsecureUserRepository.shared.save(user: user)
        AppState.shared.currentUser = user.userInfo
        AppState.shared.userState = .loggedIn
        // Perform login
        completion(user)
    }

}
