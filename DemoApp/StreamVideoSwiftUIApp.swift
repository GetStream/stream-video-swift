//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import Atlantis

@main
struct StreamVideoSwiftUIApp: App {
    
    @State var streamVideoUI: StreamVideoUI?
    
    @ObservedObject var appState = AppState.shared
        
    init() {
        Atlantis.start()
        LogConfig.level = .debug
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.userState == .loggedIn {
                CallView()
            } else {
                LoginView() { user in
                    let streamVideo = StreamVideo(
                        apiKey: "1234",
                        user: user.userInfo,
                        token: user.token,
                        videoConfig: VideoConfig(),
                        tokenProvider: { result in
                            result(.success(user.token))
                        }
                    )
                    streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
                }
            }
        }
    }
    
}
