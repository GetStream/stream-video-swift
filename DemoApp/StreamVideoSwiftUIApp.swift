//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Sentry

@main
struct StreamVideoSwiftUIApp: App {
    
    private let userRepository: UserRepository = UnsecureUserRepository.shared
    
    @State var streamVideoUI: StreamVideoUI?
    
    @ObservedObject var appState = AppState.shared
            
    init() {
        checkLoggedInUser()
        LogConfig.level = .debug
        configureSentry()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.userState == .loggedIn {
                    CallView(callId: appState.deeplinkCallId)
                } else {
                    LoginView() { user in
                        handleSelectedUser(user)
                    }
                }
            }
            .onOpenURL { url in
                handle(url: url)
            }
        }
    }
    
    private func handle(url: URL) {
        let queryParams = url.queryParameters
        let users = User.builtInUsers
        guard let userId = queryParams["user_id"],
              let callId = queryParams["call_id"] else {
            return
        }
        let user = users.filter { $0.id == userId }.first
        if let user = user {
            appState.deeplinkCallId = callId
            appState.userState = .loggedIn
            Task {
                let token = try await TokenService.shared.fetchToken(for: user.id)
                let credentials = UserCredentials(userInfo: user, token: token)
                handleSelectedUser(credentials, callId: callId)
            }
        }
    }
    
    private func handleSelectedUser(_ user: UserCredentials, callId: String? = nil) {
        let streamVideo = StreamVideo(
            apiKey: Config.apiKey,
            user: user.userInfo,
            token: user.token,
            videoConfig: VideoConfig(),
            tokenProvider: { result in
                Task {
                    do {
                        let token = try await TokenService.shared.fetchToken(for: user.id)
                        result(.success(token))
                    } catch {
                        result(.failure(error))
                    }
                }
            }
        )
        appState.streamVideo = streamVideo
        let utils = Utils(userListProvider: MockUserListProvider())
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)
    }
    
    private func checkLoggedInUser() {
        if let user = userRepository.loadCurrentUser() {
            appState.currentUser = user.userInfo
            appState.userState = .loggedIn
            handleSelectedUser(user)
        }
    }
    
    private func configureSentry() {
    #if RELEASE
        // We're tracking Crash Reports / Issues from the Demo App to keep improving the SDK
        SentrySDK.start { options in
            options.dsn = "https://88ee362df1bd400094bfbb587c10ee3b@o14368.ingest.sentry.io/4504356153393152"
            options.debug = true
            options.tracesSampleRate = 1.0
            options.enableAppHangTracking = true
        }
    #endif
    }
    
}
