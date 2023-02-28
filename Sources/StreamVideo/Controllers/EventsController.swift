//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class EventsController {
    
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    
    var onCustomEvent: ((CustomEvent) -> Void)?
    
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
    }
    
    public func send(event: CustomEventRequest) async throws {
        try await callCoordinatorController.sendEvent(
            type: event.type,
            callId: event.callId,
            callType: event.callType,
            customData: RawJSON.convert(extraData: event.extraData)
        )
    }
    
    public func customEvents() -> AsyncStream<CustomEvent> {
        let requests = AsyncStream(CustomEvent.self) { [weak self] continuation in
            self?.onCustomEvent = { event in
                continuation.yield(event)
            }
        }
        return requests
    }
}

public struct CustomEvent {
    public let callCid: String
    public let createdAt: Date
    public let extraData: [String: Any]
    public let type: String
    public let user: User
}

extension CustomVideoEvent {
    func toCustomEvent() -> CustomEvent {
        CustomEvent(
            callCid: callCid,
            createdAt: createdAt,
            extraData: mapped,
            type: type,
            user: User(
                id: user.id,
                name: user.name,
                imageURL: URL(string: user.image ?? "")
            )
        )
    }
    
    // TODO: temp solution.
    var mapped: [String: Any] {
        var result = [String: Any]()
        for (key, value) in custom {
            result[key] = value.value
        }
        return result
    }
}
