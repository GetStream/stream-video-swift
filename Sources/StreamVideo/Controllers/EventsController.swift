//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class EventsController {
    
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    
    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    var onCustomEvent: ((CustomEvent) -> Void)?
    var onNewReaction: ((CallReaction) -> Void)?
    
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
    }
    
    public func send(event: CustomEventRequest) async throws {
        let sendEventRequest = SendEventRequest(
            custom: RawJSON.convert(extraData: event.extraData),
            type: event.type.rawValue
        )
        let request = EventRequestData(
            id: event.callId,
            type: event.callType.name,
            sendEventRequest: sendEventRequest
        )
        _ = try await coordinatorClient.sendEvent(with: request)
    }
    
    public func send(reaction: CallReactionRequest) async throws {
        let request = SendReactionRequest(
            custom: RawJSON.convert(extraData: reaction.extraData),
            emojiCode: reaction.emojiCode,
            type: reaction.reactionType
        )
        let requestData = SendReactionRequestData(
            id: reaction.callId,
            type: reaction.callType.name,
            sendReactionRequest: request
        )
        _ = try await coordinatorClient.sendReaction(with: requestData)
    }
    
    public func customEvents() -> AsyncStream<CustomEvent> {
        let requests = AsyncStream(CustomEvent.self) { [weak self] continuation in
            self?.onCustomEvent = { event in
                continuation.yield(event)
            }
        }
        return requests
    }
    
    public func reactions() -> AsyncStream<CallReaction> {
        let requests = AsyncStream(CallReaction.self) { [weak self] continuation in
            self?.onNewReaction = { event in
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

public struct CallReaction {
    public let callCid: String
    public let createdAt: Date
    public let extraData: [String: Any]
    public let type: String
    public let emojiCode: String?
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
    
    var mapped: [String: Any] {
        var result = [String: Any]()
        for (key, value) in custom {
            result[key] = value.value
        }
        return result
    }
}

extension CallReactionEvent {
    func toVideoReaction() -> CallReaction {
        CallReaction(
            callCid: callCid,
            createdAt: createdAt,
            extraData: mapped,
            type: reaction.type,
            emojiCode: reaction.emojiCode,
            user: User(
                id: reaction.user.id,
                name: reaction.user.name,
                imageURL: URL(string: reaction.user.image ?? "")
            )
        )
    }
    
    var mapped: [String: Any] {
        var result = [String: Any]()
        for (key, value) in reaction.custom {
            result[key] = value.value
        }
        return result
    }
}
