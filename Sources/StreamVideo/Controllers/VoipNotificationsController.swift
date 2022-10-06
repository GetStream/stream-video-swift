//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

/// Controller that handles device management for voip notifications.
public final class VoipNotificationsController {
    
    private let callCoordinatorService: Stream_Video_CallCoordinatorService
    
    init(callCoordinatorService: Stream_Video_CallCoordinatorService) {
        self.callCoordinatorService = callCoordinatorService
    }
    
    /// Adds a device with the provided id.
    /// - Parameter id: the id of the device.
    public func addDevice(with id: String) {
        Task {
            var createDeviceRequest = Stream_Video_CreateDeviceRequest()
            var deviceInput = Stream_Video_DeviceInput()
            deviceInput.id = id
            deviceInput.pushProviderID = "apns"
            createDeviceRequest.input = deviceInput
            do {
                _ = try await callCoordinatorService.createDevice(createDeviceRequest: createDeviceRequest)
            } catch {
                log.error("Error creating a device: \(error.localizedDescription)")
            }
        }
    }
    
    /// Removes a device with the provided id.
    /// - Parameter id: the id of the device.
    public func removeDevice(with id: String) {
        Task {
            var deleteDeviceRequest = Stream_Video_DeleteDeviceRequest()
            deleteDeviceRequest.id = id
            do {
                _ = try await callCoordinatorService.deleteDevice(deleteDeviceRequest: deleteDeviceRequest)
            } catch {
                log.error("Error deleting a device: \(error.localizedDescription)")
            }
        }
    }
}
