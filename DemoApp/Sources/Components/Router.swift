//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import StreamWebRTC
import GoogleSignIn

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

        if 
            deeplinkInfo.baseURL != AppEnvironment.baseURL,
            let currentUser = appState.currentUser
        {
            Task {
                await appState.logout()
                AppEnvironment.baseURL = deeplinkInfo.baseURL
                try await handleLoggedInUserCredentials(.init(userInfo: currentUser, token: .empty), deeplinkInfo: deeplinkInfo)
            }
        } else {
            log.debug("Request to handle deeplink \(url) accepted ✅")
            if streamVideoUI != nil {
                appState.deeplinkInfo = deeplinkInfo
            } else {
                Task {
                    try await handleGuestUser(deeplinkInfo: deeplinkInfo)
                }
            }
        }
    }

    // MARK: - Private API

    private func loadLoggedInUser() async throws {
        if AppEnvironment.configuration == .test, AppEnvironment.contains(.mockJWT) {
            return
        } else if let userCredentials = AppState.shared.unsecureRepository.loadCurrentUser() {
            if userCredentials.userInfo.id.contains("@getstream") {
                GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] _,_ in
                    Task {
                        try await self?.setupUser(with: userCredentials)
                    }
                }
            } else {
                try await setupUser(with: userCredentials)
            }
        } else {
            try await handleGuestUser(deeplinkInfo: .empty)
        }
    }

    func handleLoggedInUserCredentials(
        _ credentials: UserCredentials,
        deeplinkInfo: DeeplinkInfo
    ) async throws {
        let updatedCredentials = try await {
            guard credentials.token.rawValue.isEmpty else {
                return credentials
            }

            let token = try await AuthenticationProvider.fetchToken(for: credentials.id)
            return .init(userInfo: credentials.userInfo, token: token)
        }()

        handle(
            user: updatedCredentials.userInfo,
            token: updatedCredentials.token.rawValue,
            deeplinkInfo: deeplinkInfo
        ) { result in
            Task {
                do {
                    let token = try await AuthenticationProvider.fetchToken(for: updatedCredentials.id)
                    result(.success(token))
                } catch {
                    result(.failure(error))
                }
            }
        }
    }
    
    private func setupUser(with userCredentials: UserCredentials) async throws {
        appState.currentUser = userCredentials.userInfo
        // First we sign in and then update the loggedIn state and the UI
        try await handleLoggedInUserCredentials(userCredentials, deeplinkInfo: .empty)
        appState.userState = .loggedIn
    }

    private func handleGuestUser(
        deeplinkInfo: DeeplinkInfo
    ) async throws {
        let (user, token): (User, String) = try await {
            if let currentUser = appState.currentUser {
                return (currentUser, "")
            } else {
                return try await AuthenticationProvider.createUser()
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
            apiKey: AppState.shared.apiKey,
            user: user,
            token: .init(stringLiteral: token),
            videoConfig: VideoConfig(audioProcessingModule: audioProcessingModule),
            tokenProvider: tokenProvider
        )

        if !AppEnvironment.configuration.isTest {
            streamChatWrapper = .init(user, token: token)
        }
        setUp(streamVideo: streamVideo, deeplinkInfo: deeplinkInfo, user: user)

        if user.type != .anonymous {
            appState.unsecureRepository.save(
                user: .init(
                    userInfo: user,
                    token: .init(stringLiteral: token)
                ))
        }
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
