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
    @Published var voipPushToken: String? {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self.setVoipToken()
            })
        }
    }
    @Published var pushToken: String? {
        didSet {
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
    
    private func setVoipToken() {
        if let voipPushToken, let streamVideo {
            Task {
                try await streamVideo.setVoipDevice(id: voipPushToken)
                self.voipPushToken = nil
            }
        }
    }
    
    private func setPushToken() {
        if let pushToken, let streamVideo {
            Task {
                try await streamVideo.setDevice(id: pushToken)
                self.pushToken = nil
            }
        }
    }
        
}

enum UserState {
    case notLoggedIn
    case loggedIn
}
