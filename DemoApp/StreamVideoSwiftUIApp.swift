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
    
    var streamVideo: StreamVideo
    
    @ObservedObject var appState = AppState.shared
        
    init() {
        streamVideo = StreamVideo(apiKey: "1234")
    }
    
    var body: some Scene {
        WindowGroup {
            if appState.userState == .loggedIn {
                CallView()
            } else {
                LoginView()
            }
        }
    }
    
}
