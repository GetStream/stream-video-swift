//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// An `Event` object representing an event in the chat system.
public typealias Event = StreamCore.Event

public typealias SendableEvent = StreamCore.SendableEvent

extension Event {
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

internal enum WrappedEvent: Event, Sendable, CustomStringConvertible {
    case internalEvent(Event)
    case coordinatorEvent(VideoEvent)
    
    func healthcheck() -> StreamCore.HealthCheckInfo? {
        switch self {
        case let .coordinatorEvent(event):
            if case let .typeHealthCheckEvent(healthCheckEvent) = event {
                return StreamCore.HealthCheckInfo(
                    connectionId: healthCheckEvent.connectionId
                )
            }
            if case let .typeConnectedEvent(connectedEvent) = event {
                return StreamCore.HealthCheckInfo(
                    connectionId: connectedEvent.connectionId
                )
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
        case .internalEvent:
            break
        }
        return nil
    }
    
    var name: String {
        switch self {
        case let .coordinatorEvent(event):
            return "coordinator: \(event.type)"
        case let .internalEvent(event):
            return "internal: \(event.name)"
        }
    }

    var description: String {
        switch self {
        case let .coordinatorEvent(event):
            return "coordinator: \(event)"
        case let .internalEvent(event):
            return "internal: \(event)"
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
