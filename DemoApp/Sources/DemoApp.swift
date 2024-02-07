//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import GoogleSignIn
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC
import SwiftUI

@main
struct DemoApp: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    // MARK: - State properties

    @State private var userState: UserState = .notLoggedIn
    private let router: Router

    // MARK: - Lifecycle

    init() {
        let router = Router.shared
        self.router = router

        LogConfig.level = .debug
        configureSentry()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if userState == .loggedIn {
                    NavigationView {
                        DemoCallContainerView(callId: router.appState.deeplinkInfo.callId)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(.stack)
                } else {
                    if AppEnvironment.configuration.isRelease {
                        LoadingView()
                    } else {
                        NavigationView {
                            LoginView() { credentials in
                                Task {
                                    try await router.handleLoggedInUserCredentials(
                                        credentials,
                                        deeplinkInfo: router.appState.deeplinkInfo
                                    )
                                }
                            }
                        }
                        .navigationViewStyle(.stack)
                    }
                }
            }
            .onReceive(router.appState.$userState) { self.userState = $0 }
            .preferredColorScheme(.dark)
            .onOpenURL { router.handle(url: $0) }
            .onContinueUserActivity(
                NSUserActivityTypeBrowsingWeb
            ) { $0.webpageURL.map { url in router.handle(url: url) } }
        }
    }
}
