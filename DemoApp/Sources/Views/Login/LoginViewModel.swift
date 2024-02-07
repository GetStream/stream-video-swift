//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {

    func login(user: User, callId: String = "", completion: @escaping (UserCredentials) -> Void) {
        AppState.shared.loading = true
        Task {
            let token = try await AuthenticationProvider.fetchToken(for: user.id, callIds: [callId])
            let credentials = UserCredentials(userInfo: user, token: token)
            // Perform login
            completion(credentials)
        }
    }

    func ssoLogin(_ completion: @escaping (Result<UserCredentials, Error>) -> Void) {
        AppState.shared.loading = true
        Task {
            do {
                let credentials = try await GoogleHelper.signIn()
                completion(.success(credentials))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func joinCallAnonymously(callId: String, completion: @escaping (UserCredentials) -> Void) {
        AppState.shared.loading = true
        Task {
            let token = try await AuthenticationProvider.fetchToken(for: User.anonymous.id, callIds: ["default:\(callId)"])
            let credentials = UserCredentials(userInfo: User.anonymous, token: token)
            // Perform login
            AppState.shared.activeAnonymousCallId = callId
            completion(credentials)
        }
    }
}
