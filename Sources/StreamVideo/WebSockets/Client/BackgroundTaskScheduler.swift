//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

/// Object responsible for platform specific handling of background tasks
protocol BackgroundTaskScheduler {
    /// It's your responsibility to finish previously running task.
    ///
    /// Returns: `false` if system forbid background task, `true` otherwise
    func beginTask(expirationHandler: (() -> Void)?) -> Bool
    func endTask()
    func startListeningForAppStateUpdates(
        onEnteringBackground: @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    )
    func stopListeningForAppStateUpdates()
    
    var isAppActive: Bool { get }
}

#if os(iOS)
import UIKit

class IOSBackgroundTaskScheduler: BackgroundTaskScheduler {
    private lazy var app: UIApplication? = {
        // We can't use `UIApplication.shared` directly because there's no way to convince the compiler
        // this code is accessible only for non-extension executables.
        UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication
    }()

    /// The identifier of the currently running background task. `nil` if no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier? {
        didSet {
            if let oldBackgroundTask = oldValue {
                app?.endBackgroundTask(oldBackgroundTask)
            }
        }
    }

    private var backgroundTaskExpirationCancellable: AnyCancellable?

    var isAppActive: Bool {
        let app = self.app
        if Thread.isMainThread {
            return app?.applicationState == .active
        }

        var isActive = false
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            isActive = app?.applicationState == .active
            group.leave()
        }
        group.wait()
        return isActive
    }
    
    func beginTask(expirationHandler: (() -> Void)?) -> Bool {
        let expirationHandler = { [weak self] in
            expirationHandler?()
            self?.endTask()
            self?.backgroundTaskExpirationCancellable?.cancel()
            self?.backgroundTaskExpirationCancellable = nil
        }

        backgroundTaskExpirationCancellable?.cancel()

        activeBackgroundTask = app?.beginBackgroundTask(
            expirationHandler: expirationHandler
        )

        guard activeBackgroundTask != .invalid else {
            return false
        }

        backgroundTaskExpirationCancellable = Foundation.Timer
            .publish(every: 25, on: .main, in: .default)
            .autoconnect()
            .sink { _ in expirationHandler() }

        return true
    }

    func endTask() {
        if let activeTask = activeBackgroundTask {
            app?.endBackgroundTask(activeTask)
            activeBackgroundTask = nil
        }
    }

    private var onEnteringBackground: () -> Void = {}
    private var onEnteringForeground: () -> Void = {}

    func startListeningForAppStateUpdates(
        onEnteringBackground: @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    ) {
        self.onEnteringForeground = onEnteringForeground
        self.onEnteringBackground = onEnteringBackground

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    func stopListeningForAppStateUpdates() {
        onEnteringForeground = {}
        onEnteringBackground = {}
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleAppDidEnterBackground() {
        onEnteringBackground()
    }

    @objc private func handleAppDidBecomeActive() {
        onEnteringForeground()
    }
    
    deinit {
        endTask()
    }
}

#endif
