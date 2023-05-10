//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class LivestreamController {
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    private let callId: String
    private let callType: String
    
    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    var onBroadcastingEvent: ((BroadcastingEvent) -> ())?
    
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User,
        callId: String,
        callType: String
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
        self.callId = callId
        self.callType = callType
    }
    
    func startBroadcasting() async throws {
        if !currentUserHasCapability(.startBroadcastCall) {
            throw ClientError.MissingPermissions()
        }
        try await coordinatorClient.startBroadcasting(callId: callId, callType: callType)
    }
    
    func stopBroadcasting() async throws {
        try await coordinatorClient.stopBroadcasting(callId: callId, callType: callType)
    }
    
    func broadcastingEvents() -> AsyncStream<BroadcastingEvent> {
        let callCid = callCid(from: callId, callType: callType)
        let events = AsyncStream(BroadcastingEvent.self) { [weak self] continuation in
            self?.onBroadcastingEvent = { event in
                if event.callCid == callCid {
                    continuation.yield(event)
                }
            }
        }
        return events
    }
    
    func currentUserHasCapability(_ capability: OwnCapability) -> Bool {
        let currentCallCapabilities = callCoordinatorController.currentCallSettings?.callCapabilities
        return currentCallCapabilities?.contains(
            capability.rawValue
        ) == true
    }
    
    func cleanUp() {
        onBroadcastingEvent = nil
    }
}

public protocol BroadcastingEvent: Sendable {
    var callCid: String { get }
    var type: String { get }
}

public struct BroadcastingStartedEvent: BroadcastingEvent {
    public let callCid: String
    public let createdAt: Date
    public let hlsPlaylistUrl: String
    public let type: String
}

public struct BroadcastingStoppedEvent: BroadcastingEvent {
    public let callCid: String
    public let createdAt: Date
    public let type: String
}
