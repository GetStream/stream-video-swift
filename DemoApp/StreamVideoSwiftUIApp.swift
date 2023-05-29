//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

@main
struct StreamVideoSwiftUIApp: App {
    
    private let userRepository: UserRepository = UnsecureUserRepository.shared
    
    @State var streamVideoUI: StreamVideoUI?
    
    @ObservedObject var appState = AppState.shared
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

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
                    LoginView() { user in
                        handleSelectedUser(user)
                    }
                }
            }
            .onOpenURL { url in
                DeeplinkAdapter(baseURL: Config.baseURL)
                    .handle(url: url, completion: handle)
            }
        }
    }
    
    private func handle(deeplinkInfo: DeeplinkInfo, user: User) {
        appState.deeplinkInfo = deeplinkInfo
        appState.userState = .loggedIn
        Task {
            let token = try await TokenService.shared.fetchToken(for: user.id)
            let credentials = UserCredentials(userInfo: user, token: token)
            handleSelectedUser(credentials, callId: deeplinkInfo.callId)
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
                        userRepository.save(token: token.rawValue)
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
        appState.connectUser()
    }
    
    private func checkLoggedInUser() {
        if let user = userRepository.loadCurrentUser() {
            appState.currentUser = user.userInfo
            appState.userState = .loggedIn
            handleSelectedUser(user)
        }
    }
}
