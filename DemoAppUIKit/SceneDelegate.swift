//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamVideo
import StreamVideoSwiftUI

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
            apiKey: "us83cfwuhy8n",
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

//TODO: remove this.
enum ApiKeyConfig {
    case frankfurt
    case oregon
}

extension ApiKeyConfig {
    
    var apiKey: String {
        switch self {
        case .frankfurt:
            return "w6yaq5388uym"
        case .oregon:
            return "554fuj7wzx4r"
        }
    }
    
}
