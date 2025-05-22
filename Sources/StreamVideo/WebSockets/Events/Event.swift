//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event: Sendable {}

public protocol SendableEvent: Event, ProtoModel, ReflectiveStringConvertible {}

extension Event {
    var name: String {
        String(describing: Self.self)
    }
    
    func unwrap() -> VideoEvent? {
        if let unwrapped = self as? VideoEvent {
            return unwrapped
        }
        if let wrappedEvent = self as? WrappedEvent {
            if case let .coordinatorEvent(videoEvent) = wrappedEvent {
                return videoEvent
            }
        }
        return nil
    }
    
    func forCall(cid: String) -> Bool {
        guard let videoEvent = unwrap() else {
            return false
        }
        guard let wsCallEvent = videoEvent.rawValue as? WSCallEvent else {
            return false
        }
        return wsCallEvent.callCid == cid
    }
}

/// An internal object that we use to wrap the kind of events that are handled by WS: SFU and coordinator events
enum WrappedEvent: Event, Sendable {
    case internalEvent(Event)
    case coordinatorEvent(VideoEvent)
    case sfuEvent(Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload)
    
    func healthcheck() -> HealthCheckInfo? {
        switch self {
        case let .coordinatorEvent(event):
            if case let .typeHealthCheckEvent(healthCheckEvent) = event {
                return HealthCheckInfo(coordinatorHealthCheck: healthCheckEvent)
            }
            if case let .typeConnectedEvent(connectedEvent) = event {
                return HealthCheckInfo(
                    coordinatorHealthCheck: .init(
                        cid: nil,
                        connectionId: connectedEvent.connectionId,
                        createdAt: connectedEvent.createdAt
                    )
                )
            }
        case let .sfuEvent(event):
            if case let .healthCheckResponse(healthCheckEvent) = event {
                return HealthCheckInfo(sfuHealthCheck: healthCheckEvent)
            }
        case .internalEvent:
            break
        }
        return nil
    }
    
    func error() -> Error? {
        switch self {
        case let .coordinatorEvent(event):
            if case let .typeConnectionErrorEvent(errorEvent) = event {
                return errorEvent.error
            }
        case let .sfuEvent(event):
            if case let .error(errorEvent) = event {
                return errorEvent.error
            }
            return nil
        case .internalEvent:
            break
        }
        return nil
    }
    
    var name: String {
        switch self {
        case let .coordinatorEvent(event):
            "Coordinator:\(event.type)"
        case let .sfuEvent(event):
            "SFU:\(event.name)"
        case let .internalEvent(event):
            "Internal:\(event.name)"
        }
    }
}

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload: Event {
    var name: String {
        switch self {
        case .subscriberOffer: "subscriberOffer"
        case .publisherAnswer: "publisherAnswer"
        case .connectionQualityChanged: "connectionQualityChanged"
        case .audioLevelChanged: "audioLevelChanged"
        case .iceTrickle: "iceTrickle"
        case .changePublishQuality: "changePublishQuality"
        case .participantJoined: "participantJoined"
        case .participantLeft: "participantLeft"
        case .dominantSpeakerChanged: "dominantSpeakerChanged"
        case .joinResponse: "joinResponse"
        case .healthCheckResponse: "healthCheckResponse"
        case .trackPublished: "trackPublished"
        case .trackUnpublished: "trackUnpublished"
        case .error: "error"
        case .callGrantsUpdated: "callGrantsUpdated"
        case .goAway: "goAway"
        case .iceRestart: "iceRestart"
        case .pinsUpdated: "pinsUpdated"
        case .callEnded: "callEnded"
        case .participantUpdated: "participantUpdated"
        case .participantMigrationComplete: "participantMigrationComplete"
        case .changePublishOptions: "changePublishOptions"
        }
    }
}
