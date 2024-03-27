//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Properties

    private var activeCallCancellable: AnyCancellable?

    // MARK: Published

    @Published var apiKey: String = ""
    @Published var userState: UserState = .notLoggedIn
    @Published var deeplinkInfo: DeeplinkInfo = .empty
    @Published var currentUser: User?
    @Published var loading = false
    @Published var activeCall: Call?
    @Published var activeAnonymousCallId: String = ""
    @Published var voIPPushToken: String? {
        didSet {
            if voIPPushToken != oldValue {
                unsecureRepository.save(voIPPushToken: voIPPushToken)
                didUpdate(voIPPushToken: voIPPushToken)
            }
        }
    }

    @Published var pushToken: String? {
        didSet {
            if pushToken != oldValue {
                unsecureRepository.save(pushToken: pushToken)
                didUpdate(pushToken: pushToken)
            }
        }
    }

    @Published var audioFilter: AudioFilter? { didSet { didUpdate(audioFilter: audioFilter) } }
    @Published var videoFilter: VideoFilter? { didSet { didUpdate(videoFilter: videoFilter) } }
    @Published var users: [User]

    let unsecureRepository = UnsecureRepository()
    let reactionsHelper = ReactionsHelper()

    // MARK: Mutable

    var streamVideo: StreamVideo? {
        didSet {
            didUpdate(pushToken: pushToken)
            didUpdate(voIPPushToken: voIPPushToken)
            deferSetDevice = false
            deferSetVoipDevice = false
            activeCallCancellable?.cancel()
            activeCallCancellable = nil
            if let streamVideo {
                activeCallCancellable = streamVideo
                    .state
                    .$activeCall
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.activeCall = $0 }
            }
        }
    }

    private var deferSetDevice = false
    private var deferSetVoipDevice = false

    // MARK: Immutable

    lazy var voiceProcessor = DemoVoiceProcessor()

    // MARK: Singleton

    static let shared = AppState()

    // MARK: - Lifecycle

    private init() {
        switch AppEnvironment.configuration {
        case .debug:
            users = User.builtIn
        case .test:
            users = User.builtIn
        case .release:
            users = []
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
    
    func logout() async {
        if let voipPushToken = unsecureRepository.currentVoIPPushToken() {
            do {
                try await streamVideo?.deleteDevice(id: voipPushToken)
                log.debug("✅ Removed VOIP push notification device for token: \(voipPushToken)")
            } catch {
                log.error("Removing VOIP push notification device for token: \(voipPushToken)")
            }
        }
        if let pushToken = unsecureRepository.currentPushToken() {
            do {
                try await streamVideo?.deleteDevice(id: pushToken)
                log.debug("✅ Removed push notification device for token: \(pushToken)")
            } catch {
                log.error("Removing push notification device for token: \(pushToken)")
            }
        }
        await streamVideo?.disconnect()
        unsecureRepository.removeCurrentUser()
        streamVideo = nil
        userState = .notLoggedIn
    }

    func dispatchLogout() {
        Task { await logout() }
    }

    // MARK: - Private API

    private func didUpdate(voIPPushToken: String?) {
        if let voIPPushToken, let streamVideo {
            Task {
                do {
                    try await streamVideo.setVoipDevice(id: voIPPushToken)
                    log.debug("VOIP push notification registration ✅")
                } catch {
                    log.error("VOIP push notification registration ❌:\(error)")
                }
            }
        } else if let voIPPushToken, !voIPPushToken.isEmpty {
            deferSetVoipDevice = true
            log.debug("Deferring VOIPD push notification setup for token: \(voIPPushToken)")
        } else {
            log.debug("Clearing up VOIP push notification token.")
        }
    }
    
    private func didUpdate(pushToken: String?) {
        if let pushToken, let streamVideo {
            Task {
                do {
                    try await streamVideo.setDevice(id: pushToken)
                    log.debug("Push notification registration ✅")
                } catch {
                    log.error("Push notification registration ❌:\(error)")
                }
            }
        } else if let pushToken, !pushToken.isEmpty {
            deferSetDevice = true
            log.debug("Deferring push notification setup for token: \(pushToken)")
        } else {
            log.debug("Clearing up push notification token.")
        }
    }

    private func didUpdate(audioFilter: AudioFilter?) {
        voiceProcessor.setAudioFilter(audioFilter)
    }

    private func didUpdate(videoFilter: VideoFilter?) {
        activeCall?.setVideoFilter(videoFilter)
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
