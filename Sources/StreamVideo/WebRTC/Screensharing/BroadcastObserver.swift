//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public enum BroadcastState {
    case notStarted
    case started
    case finished
}

public class BroadcastObserver: ObservableObject {
    
    @Published public var broadcastState: BroadcastState = .notStarted
    
    public init() {}
    
    lazy var broadcastStarted: CFNotificationCallback = { center, observer, name, object, userInfo in
        postNotification(with: BroadcastConstants.broadcastStartedNotification)
    }
    
    lazy var broadcastStopped: CFNotificationCallback = { center, observer, name, object, userInfo in
        postNotification(with: BroadcastConstants.broadcastStoppedNotification)
    }
    
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

    @objc func handleBroadcastStarted() {
        self.broadcastState = .started
    }
    
    @objc func handleBroadcastStopped() {
        self.broadcastState = .finished
    }
}
