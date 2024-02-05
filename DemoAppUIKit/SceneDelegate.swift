//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var streamVideoUI: StreamVideoUI?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = scene as? UIWindowScene else { return }
        self.window = UIWindow(windowScene: scene)
        guard let window = self.window else { return }
        let loginViewController = LoginViewController()
        loginViewController.onUserSelected = { userCredentials in
            self.login(userCredentials)
            let homeViewController = HomeViewController()
            let navigationController = UINavigationController(rootViewController: homeViewController)
            window.rootViewController = navigationController
        }
        window.rootViewController = loginViewController
        window.makeKeyAndVisible()
    }
    
    private func login(_ user: UserCredentials) {
        let streamVideo = StreamVideo(
            apiKey: AppState.shared.apiKey,
            user: user.userInfo,
            token: user.token,
            videoConfig: VideoConfig(),
            tokenProvider: { result in
                Task {
                    do {
                        let token = try await AuthenticationProvider.fetchToken(for: user.id)
                        result(.success(token))
                    } catch {
                        result(.failure(error))
                    }
                }
            }
        )
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
        Task {
            try await streamVideo.connect()
        }
    }
}
