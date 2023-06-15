//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
class AppState: ObservableObject {
    
    @Published var userState: UserState = .notLoggedIn
    @Published var deeplinkInfo: DeeplinkInfo = .empty
    @Published var currentUser: User?
    @Published var loading = false
    @Published var voipPushToken: String? {
        didSet {
            UnsecureUserRepository.shared.save(voipPushToken: voipPushToken)
            setVoipToken()
        }
    }
    @Published var pushToken: String? {
        didSet {
            UnsecureUserRepository.shared.save(pushToken: pushToken)
            setPushToken()
        }
    }
    @Published var activeCall: Call?
    
    var streamVideo: StreamVideo? {
        didSet {
            setPushToken()
            setVoipToken()
        }
    }
    
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
    
    func logout() {
        Task {
            if let voipPushToken = UnsecureUserRepository.shared.currentVoipPushToken() {
                _ = try? await streamVideo?.deleteDevice(id: voipPushToken)
            }
            if let pushToken = UnsecureUserRepository.shared.currentPushToken() {
                _ = try? await streamVideo?.deleteDevice(id: pushToken)
            }
            await streamVideo?.disconnect()
            UnsecureUserRepository.shared.removeCurrentUser()
            streamVideo = nil
            userState = .notLoggedIn
        }
    }
    
    private func setVoipToken() {
        if let voipPushToken, let streamVideo {
            Task {
                try await streamVideo.setVoipDevice(id: voipPushToken)
            }
        }
    }
    
    private func setPushToken() {
        if let pushToken, let streamVideo {
            Task {
                try await streamVideo.setDevice(id: pushToken)
            }
        }
    }
        
}

enum UserState {
    case notLoggedIn
    case loggedIn
}
