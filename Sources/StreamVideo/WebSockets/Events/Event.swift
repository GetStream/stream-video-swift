//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
internal enum WrappedEvent: Event, Sendable {
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
            return "Coordinator:\(event.type)"
        case let .sfuEvent(event):
            return "SFU:\(event.name)"
        case let .internalEvent(event):
            return "Internal:\(event.name)"
        }
    }
}

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload: Event {
    var name: String {
        switch self {
        case .subscriberOffer: return "subscriberOffer"
        case .publisherAnswer: return "publisherAnswer"
        case .connectionQualityChanged: return "connectionQualityChanged"
        case .audioLevelChanged: return "audioLevelChanged"
        case .iceTrickle: return "iceTrickle"
        case .changePublishQuality: return "changePublishQuality"
        case .participantJoined: return "participantJoined"
        case .participantLeft: return "participantLeft"
        case .dominantSpeakerChanged: return "dominantSpeakerChanged"
        case .joinResponse: return "joinResponse"
        case .healthCheckResponse: return "healthCheckResponse"
        case .trackPublished: return "trackPublished"
        case .trackUnpublished: return "trackUnpublished"
        case .error: return "error"
        case .callGrantsUpdated: return "callGrantsUpdated"
        case .goAway: return "goAway"
        case .iceRestart: return "iceRestart"
        case .pinsUpdated: return "pinsUpdated"
        case .callEnded: return "callEnded"
        case .participantUpdated: return "participantUpdated"
        case .participantMigrationComplete: return "participantMigrationComplete"
        case .changePublishOptions: return "changePublishOptions"
        case .inboundStateNotification: return "inboundStateNotification"
        }
    }
}
