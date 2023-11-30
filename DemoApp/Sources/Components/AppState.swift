//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import StreamVideoSwiftUI

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Properties
    // MARK: Published

    @Published var apiKey: String = ""
    @Published var userState: UserState = .notLoggedIn
    @Published var deeplinkInfo: DeeplinkInfo = .empty
    @Published var currentUser: User?
    @Published var loading = false
    @Published var activeCall: Call?
    @Published var activeAnonymousCallId: String = ""
    @Published var voIPPushToken: String? { didSet { didSet(voIPPushToken: voIPPushToken) } }
    @Published var pushToken: String? { didSet { didSet(pushToken: pushToken) } }
    @Published var audioFilter: AudioFilter? { didSet { didSet(audioFilter: audioFilter) } }
    @Published var users: [User]

    let unsecureRepository = UnsecureRepository()
    let reactionsHelper = ReactionsHelper()

    // MARK: Mutable

    var streamVideo: StreamVideo? { didSet { didSet(pushToken: nil); didSet(voIPPushToken: nil); } }

    // MARK: Immutable

    let voiceProcessor = DemoVoiceProcessor()

    // MARK: Singleton

    static let shared = AppState()

    // MARK: - Lifecycle

    private init() {
        switch AppEnvironment.configuration {
        case .debug:
            self.users = User.builtIn
        case .test:
            self.users = User.builtIn
        case .release:
            self.users = []
        }
    }
    
    // MARK: - Actions

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
            if let voipPushToken = unsecureRepository.currentVoIPPushToken() {
                _ = try? await streamVideo?.deleteDevice(id: voipPushToken)
            }
            if let pushToken = unsecureRepository.currentPushToken() {
                _ = try? await streamVideo?.deleteDevice(id: pushToken)
            }
            await streamVideo?.disconnect()
            unsecureRepository.removeCurrentUser()
            streamVideo = nil
            userState = .notLoggedIn
        }
    }

    // MARK: - Private API

    private func didSet(voIPPushToken: String?) {
        unsecureRepository.save(voIPPushToken: voIPPushToken)
        if let voIPPushToken, let streamVideo {
            Task {
                try await streamVideo.setVoipDevice(id: voIPPushToken)
            }
        }
    }
    
    private func didSet(pushToken: String?) {
        unsecureRepository.save(pushToken: pushToken)
        if let pushToken, let streamVideo {
            Task {
                try await streamVideo.setDevice(id: pushToken)
            }
        }
    }

    private func didSet(audioFilter: AudioFilter?) {
        voiceProcessor.setAudioFilter(audioFilter)
    }
}

// MARK: - UserListProvider
extension AppState: UserListProvider {

    func loadNextUsers(
        pagination: Pagination
    ) async throws -> [User] {
        users
    }
}
