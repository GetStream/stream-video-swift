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
            apiKey: Config.apiKey,
            user: user.userInfo,
            token: user.token,
            videoConfig: VideoConfig(),
            tokenProvider: { result in
                Task {
                    do {
                        let token = try await TokenService.shared.fetchToken(for: user.id)
                        UnsecureUserRepository.shared.save(token: token.rawValue)
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
