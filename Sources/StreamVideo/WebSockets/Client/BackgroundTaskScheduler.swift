//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Object responsible for platform specific handling of background tasks
protocol BackgroundTaskScheduler {
    /// It's your responsibility to finish previously running task.
    ///
    /// Returns: `false` if system forbid background task, `true` otherwise
    @MainActor func beginTask(expirationHandler: (@Sendable() -> Void)?) -> Bool
    func endTask()
    func startListeningForAppStateUpdates(
        onEnteringBackground: @MainActor @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    )
    func stopListeningForAppStateUpdates()
    
    @MainActor var isAppActive: Bool { get }
}

#if os(iOS)
import UIKit

class IOSBackgroundTaskScheduler: BackgroundTaskScheduler, @unchecked Sendable {
    private lazy var app: UIApplication? = {
        // We can't use `UIApplication.shared` directly because there's no way to convince the compiler
        // this code is accessible only for non-extension executables.
        UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication
    }()

    /// The identifier of the currently running background task. `nil` if no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier?

    var isAppActive: Bool {
        let app = self.app
        if Thread.isMainThread {
            return app?.applicationState == .active
        }

        var isActive = false
        let group = DispatchGroup()
        group.enter()
        Task { @MainActor in
            isActive = app?.applicationState == .active
            group.leave()
        }
        group.wait()
        return isActive
    }
    
    func beginTask(expirationHandler: (@Sendable() -> Void)?) -> Bool {
        activeBackgroundTask = app?.beginBackgroundTask { [weak self] in
            expirationHandler?()
            self?.endTask()
        }
        return activeBackgroundTask != .invalid
    }

    func endTask() {
        if let activeTask = activeBackgroundTask {
            Task { @MainActor [weak self] in
                self?.app?.endBackgroundTask(activeTask)
                self?.activeBackgroundTask = nil
            }
        }
    }

    private var onEnteringBackground: @MainActor() -> Void = {}
    private var onEnteringForeground: () -> Void = {}

    func startListeningForAppStateUpdates(
        onEnteringBackground: @MainActor @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    ) {
        self.onEnteringForeground = onEnteringForeground
        self.onEnteringBackground = onEnteringBackground

        Task { @MainActor in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleAppDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }
    }
    
    func stopListeningForAppStateUpdates() {
        onEnteringForeground = {}
        onEnteringBackground = {}
        
        Task { @MainActor in
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
    }

    @MainActor @objc private func handleAppDidEnterBackground() {
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
