//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import GoogleSignIn
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC
import SwiftUI
#if canImport(StreamVideoNoiseCancellation)
import StreamVideoNoiseCancellation
#endif

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
            || appState.unsecureRepository.currentBaseURL() != AppEnvironment.baseURL {
            // Clean up the currently logged in use, if we run in different
            // configuration since the last time.
            appState.unsecureRepository.removeCurrentUser()
        }

        // Store the current AppEnvironment configuration.
        appState.unsecureRepository.save(configuration: AppEnvironment.configuration)
        appState.unsecureRepository.save(baseURL: AppEnvironment.baseURL)

        switch AppEnvironment.baseURL {
        case let .custom(_, apiKey, _):
            appState.apiKey = apiKey
        default:
            break
        }

        Task {
            do {
                try await loadLoggedInUser()
            } catch {
                log.error(error)
            }
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
            let currentUser = appState.currentUser {
            Task {
                do {
                    await appState.logout()
                    AppEnvironment.baseURL = deeplinkInfo.baseURL
                    try await handleLoggedInUserCredentials(.init(userInfo: currentUser, token: .empty), deeplinkInfo: deeplinkInfo)
                } catch {
                    log.error(error)
                }
            }
        } else {
            log.debug("Request to handle deeplink \(url) accepted ✅")
            if streamVideoUI != nil {
                appState.deeplinkInfo = deeplinkInfo
            } else {
                Task {
                    do {
                        try await handleGuestUser(deeplinkInfo: deeplinkInfo)
                    } catch {
                        log.error(error)
                    }
                }
            }
        }
    }

    // MARK: - Private API

    private func loadLoggedInUser() async throws {
        if AppEnvironment.configuration == .test, AppEnvironment.contains(.mockJWT) {
            try await handleGuestUser(deeplinkInfo: .empty)
        } else if let userCredentials = AppState.shared.unsecureRepository.loadCurrentUser() {
            if userCredentials.userInfo.id.contains("@getstream") {
                GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] _, _ in
                    Task {
                        do {
                            try await self?.setupUser(with: userCredentials)
                        } catch {
                            log.error(error)
                        }
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
            deeplinkInfo: deeplinkInfo,
            tokenProvider: { [weak self] in
                self?.refreshToken(for: updatedCredentials.id, $0)
            }
        )
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

        handle(
            user: user,
            token: token,
            deeplinkInfo: deeplinkInfo,
            tokenProvider: { [weak self] in self?.refreshToken(for: user.id, $0) }
        )
    }

    private func handle(
        user: User,
        token: String,
        deeplinkInfo: DeeplinkInfo,
        tokenProvider: @escaping UserTokenProvider
    ) {
        let videoConfig: VideoConfig
        #if canImport(StreamVideoNoiseCancellation)
        let processor = NoiseCancellationProcessor()
        let noiseCancellationFilter = NoiseCancellationFilter(
            name: "noise-cancellation",
            initialize: processor.initialize,
            process: processor.process,
            release: processor.release
        )
        videoConfig = .init(noiseCancellationFilter: noiseCancellationFilter)
        #else
        videoConfig = .init()
        #endif

        let streamVideo = StreamVideo(
            apiKey: AppState.shared.apiKey,
            user: user,
            token: .init(stringLiteral: token),
            videoConfig: videoConfig,
            pushNotificationsConfig: AppState.shared.pushNotificationConfiguration,
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
                )
            )
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
        ReactionsAdapter.currentValue.streamVideo = streamVideo
        _ = DemoStatsAdapter.currentValue

        let utils = UtilsKey.currentValue
        utils.userListProvider = appState
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)

        if user?.type != .anonymous {
            appState.connectUser()
        } else {
            appState.loading = false
        }
    }

    private nonisolated func refreshToken(
        for userId: String,
        _ completionHandler: @Sendable @escaping (Result<UserToken, Error>) -> Void
    ) {
        Task {
            do {
                let token = try await AuthenticationProvider.fetchToken(for: userId)
                completionHandler(.success(token))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}
