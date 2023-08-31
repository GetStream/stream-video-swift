//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import WebRTC

@main
struct StreamVideoSwiftUIApp: App {

    // MARK: - State properties

    @State var streamVideoUI: StreamVideoUI?
    @ObservedObject var appState = AppState.shared
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    // MARK: - instance Properties

    private let userRepository: UserRepository = UnsecureUserRepository.shared

    // MARK: - Lifecycle

    init() {
        checkLoggedInUser()
        LogConfig.level = .debug
        configureSentry()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.userState == .loggedIn {
                    CallView(callId: appState.deeplinkInfo.callId)
                } else {
                    LoginView() { userCredentials in
                        handleLoggedInUserCredentials(userCredentials, deeplinkInfo: .empty)
                    }
                }
            }
            .onOpenURL { handle(url: $0) }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { $0.webpageURL.map { url in handle(url: url) } }
        }
    }

    // MARK: - Private Helpers

    private func handle(url: URL) {
        let (deeplinkInfo, user) = DeeplinkAdapter(baseURL: Config.baseURL).handle(url: url)
        guard
            deeplinkInfo != .empty
        else {
            return
        }
        handle(deeplinkInfo: deeplinkInfo, user: user)
    }

    private func handle(deeplinkInfo: DeeplinkInfo, user: User?) {
        Task {
            if let user = user {
                try await handleLoggedInUser(user, deeplinkInfo: deeplinkInfo)
            } else {
                try await handleGuestUser(deeplinkInfo: deeplinkInfo)
            }
        }
    }
    
    private func handleLoggedInUser(_ user: User, deeplinkInfo: DeeplinkInfo) async throws {
        let token = try await TokenService.shared.fetchToken(for: user.id)
        let credentials = UserCredentials(userInfo: user, token: token)
        handleLoggedInUserCredentials(credentials, deeplinkInfo: deeplinkInfo)
    }

    private func handleLoggedInUserCredentials(_ credentials: UserCredentials, deeplinkInfo: DeeplinkInfo) {
        let audioProcessingModule = RTCDefaultAudioProcessingModule(
            config: nil,
            capturePostProcessingDelegate: appState.voiceProcessor,
            renderPreProcessingDelegate: nil
        )
        let streamVideo = StreamVideo(
            apiKey: Config.apiKey,
            user: credentials.userInfo,
            token: credentials.token,
            videoConfig: VideoConfig(audioProcessingModule: audioProcessingModule),
            tokenProvider: { result in
                Task {
                    do {
                        let token = try await TokenService.shared.fetchToken(for: credentials.id)
                        userRepository.save(token: token.rawValue)
                        result(.success(token))
                    } catch {
                        result(.failure(error))
                    }
                }
            }
        )
        setUp(streamVideo: streamVideo, deeplinkInfo: deeplinkInfo, user: credentials.userInfo)
    }

    private func handleGuestUser(deeplinkInfo: DeeplinkInfo) async throws {
        let user = {
            guard let currentUser = appState.currentUser, currentUser.id == currentUser.name else {
                return User.guest(String(UUID().uuidString.prefix(8)))
            }
            return currentUser
        }()
        let streamVideo = StreamVideo(
            apiKey: Config.apiKey,
            user: user,
            token: .empty,
            tokenProvider: { _ in }
        )
        setUp(streamVideo: streamVideo, deeplinkInfo: deeplinkInfo, user: user)
    }

    private func setUp(streamVideo: StreamVideo, deeplinkInfo: DeeplinkInfo, user: User?) {
        appState.deeplinkInfo = deeplinkInfo
        appState.currentUser = user
        appState.userState = .loggedIn
        appState.streamVideo = streamVideo
        let utils = Utils(userListProvider: MockUserListProvider())
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)
    }
    
    private func checkLoggedInUser() {
        #if STREAM_E2E_TESTS
        if ProcessInfo.processInfo.arguments.contains("MOCK_JWT") {
            return
        }
        #endif
        
        if let userCredentials = userRepository.loadCurrentUser() {
            appState.currentUser = userCredentials.userInfo
            appState.userState = .loggedIn
            handleLoggedInUserCredentials(userCredentials, deeplinkInfo: .empty)
        }
    }
}

extension RTCDefaultAudioProcessingModule: AudioProcessingModule, @unchecked Sendable {}
