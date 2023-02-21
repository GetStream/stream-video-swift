//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Controller that handles device management for voip notifications.
public final class VoipNotificationsController {
    
    private let coordinatorClient: CoordinatorClient
    
    init(coordinatorClient: CoordinatorClient) {
        self.coordinatorClient = coordinatorClient
    }
    
    /// Adds a device with the provided id.
    /// - Parameter id: the id of the device.
    public func addDevice(with id: String) {
        // TODO: Not implemented.
    }
    
    /// Removes a device with the provided id.
    /// - Parameter id: the id of the device.
    public func removeDevice(with id: String) {
        // TODO: not implemented.
    }
}
