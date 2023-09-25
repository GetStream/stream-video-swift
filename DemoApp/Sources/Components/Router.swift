//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import WebRTC

@MainActor
final class Router: ObservableObject {

    // MARK: - Properties
    // MARK: Singleton

    static let shared = Router(.shared)

    // MARK: Instance
    var streamVideoUI: StreamVideoUI?
    var streamChatWrapper: DemoChatAdapter?
    private lazy var deeplinkAdapter = DeeplinkAdapter()

    // MARK: Published
    let appState: AppState

    // MARK: - Lifecycle

    private init(_ appState: AppState) {
        self.appState = appState

        if 
            appState.unsecureRepository.currentConfiguration() != AppEnvironment.configuration
                || appState.unsecureRepository.currentBaseURL() != AppEnvironment.baseURL
        {
            // Clean up the currently logged in use, if we run in different
            // configuration since the last time.
            appState.unsecureRepository.removeCurrentUser()
        }

        // Store the current AppEnvironment configuration.
        appState.unsecureRepository.save(configuration: AppEnvironment.configuration)
        appState.unsecureRepository.save(baseURL: AppEnvironment.baseURL)

        Task {
            try await loadLoggedInUser()
        }
    }

    // MARK: - Handle URL

    func handle(url: URL) {
        log.debug("Request to handle deeplink \(url)")
        let (deeplinkInfo, _) = deeplinkAdapter.handle(url: url)

        guard
            deeplinkInfo != .empty
        else {
            log.warning("Request to handle deeplink \(url) denied ❌")
            return
        }

        log.debug("Request to handle deeplink \(url) accepted ✅")
        if streamVideoUI != nil {
            appState.deeplinkInfo = deeplinkInfo
        } else {
            Task {
                try await handleGuestUser(deeplinkInfo: deeplinkInfo)
            }
        }
    }

    // MARK: - Private API

    private func loadLoggedInUser() async throws {
        if AppEnvironment.configuration == .test, AppEnvironment.contains(.mockJWT) {
            return
        } else if let userCredentials = AppState.shared.unsecureRepository.loadCurrentUser() {
            appState.currentUser = userCredentials.userInfo
            appState.userState = .loggedIn
            handleLoggedInUserCredentials(userCredentials, deeplinkInfo: .empty)
        } else {
            try await handleGuestUser(deeplinkInfo: .empty)
        }
    }

    func handleLoggedInUserCredentials(
        _ credentials: UserCredentials,
        deeplinkInfo: DeeplinkInfo
    ) {
        handle(
            user: credentials.userInfo,
            token: credentials.token.rawValue,
            deeplinkInfo: deeplinkInfo
        ) { result in
            Task {
                do {
                    let token = try await TokenProvider.fetchToken(for: credentials.id)
                    AppState.shared.unsecureRepository.save(token: token.rawValue)
                    result(.success(token))
                } catch {
                    result(.failure(error))
                }
            }
        }
    }

    private func handleGuestUser(
        deeplinkInfo: DeeplinkInfo
    ) async throws {
        let (user, token): (User, String) = try await {
            if let currentUser = appState.currentUser {
                return (currentUser, "")
            } else {
                return try await UserProvider.createUser()
            }
        }()

        handle(user: user, token: token, deeplinkInfo: deeplinkInfo)
    }

    private func handle(
        user: User,
        token: String,
        deeplinkInfo: DeeplinkInfo,
        tokenProvider: @escaping UserTokenProvider = { _ in }
    ) {
        let audioProcessingModule = RTCDefaultAudioProcessingModule(
            config: nil,
            capturePostProcessingDelegate: appState.voiceProcessor,
            renderPreProcessingDelegate: nil
        )

        let streamVideo = StreamVideo(
            apiKey: AppEnvironment.apiKey.rawValue,
            user: user,
            token: .init(stringLiteral: token),
            videoConfig: VideoConfig(audioProcessingModule: audioProcessingModule),
            tokenProvider: tokenProvider
        )

        if !AppEnvironment.configuration.isTest {
            streamChatWrapper = .init(user, token: token)
        }
        setUp(streamVideo: streamVideo, deeplinkInfo: deeplinkInfo, user: user)

        appState.unsecureRepository.save(
            user: .init(
                userInfo: user,
                token: .init(stringLiteral: token)
            ))
    }

    private func setUp(
        streamVideo: StreamVideo,
        deeplinkInfo: DeeplinkInfo,
        user: User?
    ) {
        appState.deeplinkInfo = deeplinkInfo
        appState.currentUser = user
        appState.userState = .loggedIn

        appState.streamVideo = streamVideo
        let utils = Utils(userListProvider: appState)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)

        appState.connectUser()
    }
}
