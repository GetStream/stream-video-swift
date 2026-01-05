//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Enum representing different states of a broadcast.
public enum BroadcastState {
    case notStarted
    case started
    case finished
}

/// Class responsible for observing broadcast state changes.
public class BroadcastObserver: ObservableObject {

    /// Published property to track the current state of the broadcast.
    @Published public var broadcastState: BroadcastState = .notStarted

    /// Initializes a new instance of `BroadcastObserver`.
    public init() {}

    /// Callback function triggered when the broadcast starts.
    lazy var broadcastStarted: CFNotificationCallback = { _, _, _, _, _ in
        postNotification(with: BroadcastConstants.broadcastStartedNotification)
    }

    /// Callback function triggered when the broadcast stops.
    lazy var broadcastStopped: CFNotificationCallback = { _, _, _, _, _ in
        postNotification(with: BroadcastConstants.broadcastStoppedNotification)
    }

    /// Initiates the observation of broadcast notifications.
    public func observe() {
        observe(
            notification: BroadcastConstants.broadcastStartedNotification,
            function: broadcastStarted
        )
        observe(
            notification: BroadcastConstants.broadcastStoppedNotification,
            function: broadcastStopped
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBroadcastStarted),
            name: NSNotification.Name(BroadcastConstants.broadcastStartedNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBroadcastStopped),
            name: NSNotification.Name(BroadcastConstants.broadcastStoppedNotification),
            object: nil
        )
    }

    /// Registers a notification observer with a specific callback function.
    private func observe(notification: String, function: CFNotificationCallback) {
        let cfstr = notification as CFString
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            notificationCenter,
            nil,
            function,
            cfstr,
            nil,
            .deliverImmediately
        )
    }

    /// Method triggered when the broadcast starts to update the state to `.started`.
    @objc func handleBroadcastStarted() {
        broadcastState = .started
    }

    /// Method triggered when the broadcast stops to update the state to `.finished`.
    @objc func handleBroadcastStopped() {
        broadcastState = .finished
    }
}
