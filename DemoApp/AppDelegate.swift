//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @Injected(\.streamVideo) var streamVideo

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        setupRemoteNotifications()
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

    func setupRemoteNotifications() {
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
}
