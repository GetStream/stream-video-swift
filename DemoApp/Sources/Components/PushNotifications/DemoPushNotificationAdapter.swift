//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import UIKit
import UserNotifications

final class DemoPushNotificationAdapter: NSObject, UNUserNotificationCenterDelegate {

    override init() {
        super.init()
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    Task { @MainActor in
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        log.debug("Will present received push notification: \(notification).")
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        do {
            try await handleNotification(response)
        } catch {
            log.error(error)
        }
    }

    // MARK: - Private Helpers

    private func handleNotification(
        _ response: UNNotificationResponse
    ) async throws {
        guard
            let userInfo = response.notification.request.content.userInfo["aps"] as? [String: Any]
        else {
            throw ClientError("Invalid push notification format.")
        }

        if let request = JoinCallRequestPayload(userInfo) {
            log.debug("Received join call push notification.")
            fireDeeplink(for: request)
        } else {
            log.debug("Unhandled push notification received.")
        }
    }

    private func fireDeeplink(for request: JoinCallRequestPayload) {
        let joinCallURL = request
            .environment
            .joinLink(
                request.id,
                callType: request.type,
                apiKey: request.apiKey,
                userId: request.userId,
                token: request.token
            )

        Task { @MainActor in
            #if targetEnvironment(simulator)
            Router.shared.handle(url: joinCallURL)
            #else
            UIApplication.shared.open(joinCallURL)
            #endif
        }
    }
}

extension DemoPushNotificationAdapter: InjectionKey {
    static var currentValue: DemoPushNotificationAdapter = .init()
}

extension InjectedValues {
    var pushNotificationAdapter: DemoPushNotificationAdapter {
        get { Self[DemoPushNotificationAdapter.self] }
        set { _ = newValue }
    }
}

struct JoinCallRequestPayload {
    var environment: AppEnvironment.BaseURL
    var type: String
    var id: String
    var apiKey: String?
    var userId: String?
    var token: String?

    init?(_ container: [AnyHashable: Any]) {
        guard
            let root = container["stream"] as? [String: Any],
            let cId = (root["call_cid"] as? String) ?? (root["cid"] as? String)
        else {
            return nil
        }

        let components = cId.components(separatedBy: ":")

        guard components.count == 2 else {
            return nil
        }

        type = components[0]
        id = components[1]

        if let appEnvironment = root["environment"] as? String {
            switch appEnvironment {
            case AppEnvironment.BaseURL.pronto.identifier:
                environment = .pronto
            case AppEnvironment.BaseURL.prontoStaging.identifier:
                environment = .prontoStaging
            case AppEnvironment.BaseURL.demo.identifier:
                environment = .demo
            default:
                environment = AppEnvironment.baseURL
            }
        } else {
            environment = AppEnvironment.baseURL
        }

        apiKey = root["api_key"] as? String
        userId = root["user_id"] as? String
        token = root["token"] as? String
    }
}
