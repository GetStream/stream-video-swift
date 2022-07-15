//
//  StreamVideoSwiftUIApp.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

@main
struct StreamVideoSwiftUIApp: App {
    
    @State var streamVideo: StreamVideo?
    
    @ObservedObject var appState = AppState.shared
        
    init() {
        LogConfig.level = .debug
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.userState == .loggedIn {
                CallView()
            } else {
                LoginView() { user in
                    streamVideo = StreamVideo(
                        apiKey: "1234",
                        user: user.userInfo,
                        token: user.token,
                        tokenProvider: { result in
                            result(.success(user.token))
                        }
                    )
                }
            }
        }
    }
    
}
