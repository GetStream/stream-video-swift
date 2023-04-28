//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class EventsController {
    
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    private let callId: String
    private let callType: String

    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    /// A closure that is called when a custom event is received.
    var onCustomEvent: ((CustomEvent) -> Void)?
    /// A closure that is called when a new reaction is received.
    var onNewReaction: ((CallReaction) -> Void)?
    
    /// Initializes a new instance of the controller.
    /// - Parameters:
    ///   - callCoordinatorController: The `CallCoordinatorController` instance that manages the call.
    ///   - currentUser: The `User` model representing the current user.
    ///   - callId: The id of the call.
    ///   - callType: The call type.
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
    
    /// Sends a custom event to the call.
    /// - Parameter event: The `CustomEventRequest` object representing the custom event to send.
    /// - Throws: An error if the sending fails.
    func send(event: CustomEventRequest) async throws {
        let sendEventRequest = SendEventRequest(
            custom: RawJSON.convert(customData: event.customData),
            type: event.type.rawValue
        )
        let request = EventRequestData(
            id: event.callId,
            type: event.callType,
            sendEventRequest: sendEventRequest
        )
        _ = try await coordinatorClient.sendEvent(with: request)
    }
    
    /// Sends a reaction to the call.
    /// - Parameter reaction: The `CallReactionRequest` object representing the reaction to send.
    /// - Throws: An error if the sending fails.
    func send(reaction: CallReactionRequest) async throws {
        let request = SendReactionRequest(
            custom: RawJSON.convert(customData: reaction.customData),
            emojiCode: reaction.emojiCode,
            type: reaction.reactionType
        )
        let requestData = SendReactionRequestData(
            id: reaction.callId,
            type: reaction.callType,
            sendReactionRequest: request
        )
        _ = try await coordinatorClient.sendReaction(with: requestData)
    }
    
    /// Returns an asynchronous stream of custom events received during the call.
    /// - Returns: An `AsyncStream` of `CustomEvent` objects.
    func customEvents() -> AsyncStream<CustomEvent> {
        let callCid = callCid(from: callId, callType: callType)
        let requests = AsyncStream(CustomEvent.self) { [weak self] continuation in
            self?.onCustomEvent = { event in
                if event.callCid == callCid {
                    continuation.yield(event)
                }
            }
        }
        return requests
    }
    
    /// Returns an asynchronous stream of reactions received during the call.
    /// - Returns: An `AsyncStream` of `CallReaction` objects.
    func reactions() -> AsyncStream<CallReaction> {
        let callCid = callCid(from: callId, callType: callType)
        let requests = AsyncStream(CallReaction.self) { [weak self] continuation in
            self?.onNewReaction = { event in
                if event.callCid == callCid {
                    continuation.yield(event)
                }
            }
        }
        return requests
    }
    
    func cleanUp() {
        self.onCustomEvent = nil
        self.onNewReaction = nil
    }
}

public struct CustomEvent {
    public let callCid: String
    public let createdAt: Date
    public let customData: [String: Any]
    public let type: String
    public let user: User
}

public struct CallReaction {
    public let callCid: String
    public let createdAt: Date
    public let customData: [String: Any]
    public let type: String
    public let emojiCode: String?
    public let user: User
}

extension CustomVideoEvent {
    func toCustomEvent() -> CustomEvent {
        CustomEvent(
            callCid: callCid,
            createdAt: createdAt,
            customData: mapped,
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
            customData: mapped,
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
