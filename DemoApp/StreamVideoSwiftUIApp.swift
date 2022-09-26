//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Atlantis

@main
struct StreamVideoSwiftUIApp: App {
    
    private let userRepository: UserRepository = UnsecureUserRepository.shared
    
    @State var streamVideoUI: StreamVideoUI?
    
    @ObservedObject var appState = AppState.shared
        
    init() {
        checkLoggedInUser()
        Atlantis.start()
        LogConfig.level = .debug
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
        let users = UserCredentials.builtInUsers
        guard let userId = queryParams["user_id"],
              let callId = queryParams["call_id"] else {
            return
        }
        let user = users.filter { $0.id == userId }.first
        if let user = user {
            appState.deeplinkCallId = callId
            appState.userState = .loggedIn
            handleSelectedUser(user, callId: callId)
        }
    }
    
    private func handleSelectedUser(_ user: UserCredentials, callId: String? = nil) {
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: user.userInfo,
            token: user.token,
            videoConfig: VideoConfig(
                persitingSocketConnection: true,
                joinVideoCallInstantly: false
            ),
            tokenProvider: { result in
                result(.success(user.token))
            }
        )
        appState.streamVideo = streamVideo
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
    }
    
    private func checkLoggedInUser() {
        if let user = userRepository.loadCurrentUser() {
            appState.currentUser = user.userInfo
            appState.userState = .loggedIn
            handleSelectedUser(user)
        }
    }
    
}
