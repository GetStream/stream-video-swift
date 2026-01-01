//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var router: Router = .shared
    private var userState: UserState? {
        didSet { didUpdateUserState(userState, oldValue: oldValue) }
    }

    private var userStateCancellable: AnyCancellable?

    private var loggedOutView: UIViewController {
        UIHostingController(
            rootView: NavigationView {
                LoginView { [router] credentials in
                    Task {
                        do {
                            try await router.handleLoggedInUserCredentials(
                                credentials,
                                deeplinkInfo: router.appState.deeplinkInfo
                            )
                        } catch {
                            log.error(error)
                        }
                    }
                }
            }
        )
    }

    private var loggedInView: UIViewController {
        UINavigationController(rootViewController: HomeViewController())
    }

    override init() {
        super.init()
        userStateCancellable = router
            .appState
            .$userState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.userState = $0 }
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = scene as? UIWindowScene else { return }
        self.window = UIWindow(windowScene: scene)
        guard let window = self.window else { return }
        window.makeKeyAndVisible()
    }

    // MARK: - Private Helpers

    private func didUpdateUserState(
        _ userState: UserState?,
        oldValue: UserState?
    ) {
        guard let userState, userState != oldValue else {
            return
        }

        switch userState {
        case .notLoggedIn:
            window?.replace(root: loggedOutView, animated: true)
        case .loggedIn:
            window?.replace(root: loggedInView, animated: true)
        }
    }
}

extension UIWindow {

    func replace(root newRootViewController: UIViewController, animated: Bool) {
        // Assuming window is your UIWindow instance
        let oldRootViewController = rootViewController

        guard animated else {
            rootViewController = newRootViewController
            return
        }

        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: { [weak self] in self?.rootViewController = newRootViewController },
            completion: { completed in
                guard completed else { return }
                // Optional completion handler
                oldRootViewController?.dismiss(animated: false, completion: nil)
            }
        )
    }
}
