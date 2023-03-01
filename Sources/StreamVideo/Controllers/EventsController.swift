//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class EventsController {
    
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    
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
        try await callCoordinatorController.sendEvent(
            type: event.type,
            callId: event.callId,
            callType: event.callType,
            customData: RawJSON.convert(extraData: event.extraData)
        )
    }
    
    public func send(reaction: CallReactionRequest) async throws {
        try await callCoordinatorController.sendReaction(
            callId: reaction.callId,
            callType: reaction.callType,
            reactionType: reaction.reactionType,
            emojiCode: reaction.emojiCode,
            customData: RawJSON.convert(extraData: reaction.extraData)
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
