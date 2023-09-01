//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

@MainActor
final class LoginViewModel: ObservableObject {

    func login(user: User, callId: String = "", completion: @escaping (UserCredentials) -> ()) {
        AppState.shared.loading = true
        Task {
            let token = try await TokenProvider.fetchToken(for: user.id, callIds: [callId])
            let credentials = UserCredentials(userInfo: user, token: token)
            // Perform login
            completion(credentials)
        }
    }

    func joinCallAnonymously(callId: String, completion: @escaping (UserCredentials) -> ()) {
        AppState.shared.loading = true
        Task {
            let token = try await TokenProvider.fetchToken(for: User.anonymous.id, callIds: ["default:\(callId)"])
            let credentials = UserCredentials(userInfo: User.anonymous, token: token)
            // Perform login
            completion(credentials)
            AppState.shared.activeAnonymousCallId = callId
        }
    }
}
