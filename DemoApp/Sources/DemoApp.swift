//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC
import GoogleSignIn

@main
struct DemoApp: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    // MARK: - State properties

    @StateObject var appState: AppState
    private let router: Router

    // MARK: - Lifecycle

    init() {
        let router = Router.shared
        self._appState = .init(wrappedValue: router.appState)
        self.router = router

        LogConfig.level = .debug
        configureSentry()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.userState == .loggedIn {
                    NavigationView {
                        DemoCallContainerView(callId: appState.deeplinkInfo.callId)
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
                                    try await router.handleLoggedInUserCredentials(credentials, deeplinkInfo: .empty)
                                }
                            }
                        }
                        .navigationViewStyle(.stack)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onOpenURL { router.handle(url: $0) }
            .onContinueUserActivity(
                NSUserActivityTypeBrowsingWeb
            ) { $0.webpageURL.map { url in router.handle(url: url) } }
        }
    }
}
