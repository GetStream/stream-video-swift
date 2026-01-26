//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import GDPerformanceView_Swift
import StreamVideo
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, @MainActor UNUserNotificationCenterDelegate {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.permissions) var permissions

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        setUpRemoteNotifications()
        setUpPerformanceTracking()

        // Setup a dummy video file to loop when working with from the simulator
        InjectedValues[\.simulatorStreamFile] = Bundle.main.url(forResource: "test", withExtension: "mp4")

        return true
    }

    /// Method used to handle custom URL schemes
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        Router.shared.handle(url: url)
        return true
    }

    /// Method used to handle universal deeplinks
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping (
            [UIUserActivityRestoring]?
        ) -> Void
    ) -> Bool {
        guard let url = userActivity.webpageURL else {
            return false
        }
        Router.shared.handle(url: url)
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let deviceToken = deviceToken.map { String(format: "%02x", $0) }.joined()
        AppState.shared.pushToken = deviceToken
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        log.debug("push notification received \(userInfo)")
        guard let stream = userInfo["stream"] as? [String: Any],
              let callCid = stream["call_cid"] as? String else {
            return
        }
        let components = callCid.components(separatedBy: ":")
        if components.count >= 2 {
            let callType = components[0]
            let callId = components[1]
            let call = streamVideo.call(callType: callType, callId: callId)
            AppState.shared.activeCall = call
            Task {
                do {
                    try Task.checkCancellation()
                    try await streamVideo.connect()

                    try Task.checkCancellation()
                    try await call.accept()

                    try Task.checkCancellation()
                    try await call.join()
                } catch {
                    log.error(error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func setUpRemoteNotifications() {
        Task {
            do {
                guard
                    try await permissions.requestPushNotificationPermission(with: [.alert, .sound, .badge])
                else {
                    log.warning("Push notifications request not granted.")
                    return
                }
                _ = await Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }.result
            } catch {
                log.error("Push notifications request failed.", error: error)
            }
        }
    }

    private func setUpPerformanceTracking() {
        guard AppEnvironment.performanceTrackerVisibility == .visible else { return }
        // PerformanceMonitor seems to have a bug where it cannot find the
        // hierarchy when trying to place its view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PerformanceMonitor.shared().performanceViewConfigurator.options = [
                .performance
            ]
            PerformanceMonitor.shared().start()
        }
    }
}
