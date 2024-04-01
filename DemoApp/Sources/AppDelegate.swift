//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import GDPerformanceView_Swift
import StreamVideo
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    @Injected(\.streamVideo) var streamVideo

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // We make sure that that VoIP push notification handling is initialized.
        _ = CallService.shared

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
                try await streamVideo.connect()
                try await call.accept()
                try await call.join()
            }
        }
    }

    // MARK: - Private Helpers

    private func setUpRemoteNotifications() {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
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
