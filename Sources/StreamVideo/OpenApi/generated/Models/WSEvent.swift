//
// WSEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** The discriminator object for all websocket events, it maps events&#39; payload to the final type */

internal class WSEventMapping: Decodable {
    let type: String
}

public enum VideoEvent: Codable, JSONEncodable, Hashable {
    case typeHealthCheckEvent(HealthCheckEvent)
    case typeCustomVideoEvent(CustomVideoEvent)
    case typeBlockedUserEvent(BlockedUserEvent)
    case typeCallAcceptedEvent(CallAcceptedEvent)
    case typeCallCreatedEvent(CallCreatedEvent)
    case typeCallDeletedEvent(CallDeletedEvent)
    case typeCallEndedEvent(CallEndedEvent)
    case typeCallHLSBroadcastingFailedEvent(CallHLSBroadcastingFailedEvent)
    case typeCallHLSBroadcastingStartedEvent(CallHLSBroadcastingStartedEvent)
    case typeCallHLSBroadcastingStoppedEvent(CallHLSBroadcastingStoppedEvent)
    case typeCallLiveStartedEvent(CallLiveStartedEvent)
    case typeCallMemberAddedEvent(CallMemberAddedEvent)
    case typeCallMemberRemovedEvent(CallMemberRemovedEvent)
    case typeCallMemberUpdatedEvent(CallMemberUpdatedEvent)
    case typeCallMemberUpdatedPermissionEvent(CallMemberUpdatedPermissionEvent)
    case typeCallNotificationEvent(CallNotificationEvent)
    case typeCallReactionEvent(CallReactionEvent)
    case typeCallRecordingFailedEvent(CallRecordingFailedEvent)
    case typeCallRecordingReadyEvent(CallRecordingReadyEvent)
    case typeCallRecordingStartedEvent(CallRecordingStartedEvent)
    case typeCallRecordingStoppedEvent(CallRecordingStoppedEvent)
    case typeCallRejectedEvent(CallRejectedEvent)
    case typeCallRingEvent(CallRingEvent)
    case typeCallSessionEndedEvent(CallSessionEndedEvent)
    case typeCallSessionParticipantJoinedEvent(CallSessionParticipantJoinedEvent)
    case typeCallSessionParticipantLeftEvent(CallSessionParticipantLeftEvent)
    case typeCallSessionStartedEvent(CallSessionStartedEvent)
    case typeCallTranscriptionFailedEvent(CallTranscriptionFailedEvent)
    case typeCallTranscriptionReadyEvent(CallTranscriptionReadyEvent)
    case typeCallTranscriptionStartedEvent(CallTranscriptionStartedEvent)
    case typeCallTranscriptionStoppedEvent(CallTranscriptionStoppedEvent)
    case typeCallUpdatedEvent(CallUpdatedEvent)
    case typeCallUserMutedEvent(CallUserMutedEvent)
    case typeClosedCaptionEvent(ClosedCaptionEvent)
    case typeConnectedEvent(ConnectedEvent)
    case typeConnectionErrorEvent(ConnectionErrorEvent)
    case typePermissionRequestEvent(PermissionRequestEvent)
    case typeUnblockedUserEvent(UnblockedUserEvent)
    case typeUpdatedCallPermissionsEvent(UpdatedCallPermissionsEvent)
    case typeUserBannedEvent(UserBannedEvent)
    case typeUserDeactivatedEvent(UserDeactivatedEvent)
    case typeUserDeletedEvent(UserDeletedEvent)
    case typeUserMutedEvent(UserMutedEvent)
    case typeUserPresenceChangedEvent(UserPresenceChangedEvent)
    case typeUserReactivatedEvent(UserReactivatedEvent)
    case typeUserUnbannedEvent(UserUnbannedEvent)
    case typeUserUpdatedEvent(UserUpdatedEvent)
    public var type: String {
        switch self {
        case .typeBlockedUserEvent(let value):
            return value.type
        case .typeCallAcceptedEvent(let value):
            return value.type
        case .typeCallCreatedEvent(let value):
            return value.type
        case .typeCallDeletedEvent(let value):
            return value.type
        case .typeCallEndedEvent(let value):
            return value.type
        case .typeCallHLSBroadcastingFailedEvent(let value):
            return value.type
        case .typeCallHLSBroadcastingStartedEvent(let value):
            return value.type
        case .typeCallHLSBroadcastingStoppedEvent(let value):
            return value.type
        case .typeCallLiveStartedEvent(let value):
            return value.type
        case .typeCallMemberAddedEvent(let value):
            return value.type
        case .typeCallMemberRemovedEvent(let value):
            return value.type
        case .typeCallMemberUpdatedEvent(let value):
            return value.type
        case .typeCallMemberUpdatedPermissionEvent(let value):
            return value.type
        case .typeCallNotificationEvent(let value):
            return value.type
        case .typeCallReactionEvent(let value):
            return value.type
        case .typeCallRecordingFailedEvent(let value):
            return value.type
        case .typeCallRecordingReadyEvent(let value):
            return value.type
        case .typeCallRecordingStartedEvent(let value):
            return value.type
        case .typeCallRecordingStoppedEvent(let value):
            return value.type
        case .typeCallRejectedEvent(let value):
            return value.type
        case .typeCallRingEvent(let value):
            return value.type
        case .typeCallSessionEndedEvent(let value):
            return value.type
        case .typeCallSessionParticipantJoinedEvent(let value):
            return value.type
        case .typeCallSessionParticipantLeftEvent(let value):
            return value.type
        case .typeCallSessionStartedEvent(let value):
            return value.type
        case .typeCallTranscriptionFailedEvent(let value):
            return value.type
        case .typeCallTranscriptionReadyEvent(let value):
            return value.type
        case .typeCallTranscriptionStartedEvent(let value):
            return value.type
        case .typeCallTranscriptionStoppedEvent(let value):
            return value.type
        case .typeCallUpdatedEvent(let value):
            return value.type
        case .typeCallUserMutedEvent(let value):
            return value.type
        case .typeClosedCaptionEvent(let value):
            return value.type
        case .typeConnectedEvent(let value):
            return value.type
        case .typeConnectionErrorEvent(let value):
            return value.type
        case .typeCustomVideoEvent(let value):
            return value.type
        case .typeHealthCheckEvent(let value):
            return value.type
        case .typePermissionRequestEvent(let value):
            return value.type
        case .typeUnblockedUserEvent(let value):
            return value.type
        case .typeUpdatedCallPermissionsEvent(let value):
            return value.type
        case .typeUserBannedEvent(let value):
            return value.type
        case .typeUserDeactivatedEvent(let value):
            return value.type
        case .typeUserDeletedEvent(let value):
            return value.type
        case .typeUserMutedEvent(let value):
            return value.type
        case .typeUserPresenceChangedEvent(let value):
            return value.type
        case .typeUserReactivatedEvent(let value):
            return value.type
        case .typeUserUnbannedEvent(let value):
            return value.type
        case .typeUserUpdatedEvent(let value):
            return value.type
        }
    }
    public var rawValue: Event {
        switch self {
        case .typeBlockedUserEvent(let value):
            return value
        case .typeCallAcceptedEvent(let value):
            return value
        case .typeCallCreatedEvent(let value):
            return value
        case .typeCallDeletedEvent(let value):
            return value
        case .typeCallEndedEvent(let value):
            return value
        case .typeCallHLSBroadcastingFailedEvent(let value):
            return value
        case .typeCallHLSBroadcastingStartedEvent(let value):
            return value
        case .typeCallHLSBroadcastingStoppedEvent(let value):
            return value
        case .typeCallLiveStartedEvent(let value):
            return value
        case .typeCallMemberAddedEvent(let value):
            return value
        case .typeCallMemberRemovedEvent(let value):
            return value
        case .typeCallMemberUpdatedEvent(let value):
            return value
        case .typeCallMemberUpdatedPermissionEvent(let value):
            return value
        case .typeCallNotificationEvent(let value):
            return value
        case .typeCallReactionEvent(let value):
            return value
        case .typeCallRecordingFailedEvent(let value):
            return value
        case .typeCallRecordingReadyEvent(let value):
            return value
        case .typeCallRecordingStartedEvent(let value):
            return value
        case .typeCallRecordingStoppedEvent(let value):
            return value
        case .typeCallRejectedEvent(let value):
            return value
        case .typeCallRingEvent(let value):
            return value
        case .typeCallSessionEndedEvent(let value):
            return value
        case .typeCallSessionParticipantJoinedEvent(let value):
            return value
        case .typeCallSessionParticipantLeftEvent(let value):
            return value
        case .typeCallSessionStartedEvent(let value):
            return value
        case .typeCallTranscriptionFailedEvent(let value):
            return value
        case .typeCallTranscriptionReadyEvent(let value):
            return value
        case .typeCallTranscriptionStartedEvent(let value):
            return value
        case .typeCallTranscriptionStoppedEvent(let value):
            return value
        case .typeCallUpdatedEvent(let value):
            return value
        case .typeCallUserMutedEvent(let value):
            return value
        case .typeClosedCaptionEvent(let value):
            return value
        case .typeConnectedEvent(let value):
            return value
        case .typeConnectionErrorEvent(let value):
            return value
        case .typeCustomVideoEvent(let value):
            return value
        case .typeHealthCheckEvent(let value):
            return value
        case .typePermissionRequestEvent(let value):
            return value
        case .typeUnblockedUserEvent(let value):
            return value
        case .typeUpdatedCallPermissionsEvent(let value):
            return value
        case .typeUserBannedEvent(let value):
            return value
        case .typeUserDeactivatedEvent(let value):
            return value
        case .typeUserDeletedEvent(let value):
            return value
        case .typeUserMutedEvent(let value):
            return value
        case .typeUserPresenceChangedEvent(let value):
            return value
        case .typeUserReactivatedEvent(let value):
            return value
        case .typeUserUnbannedEvent(let value):
            return value
        case .typeUserUpdatedEvent(let value):
            return value
        }
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .typeBlockedUserEvent(let value):
            try container.encode(value)
        case .typeCallAcceptedEvent(let value):
            try container.encode(value)
        case .typeCallCreatedEvent(let value):
            try container.encode(value)
        case .typeCallDeletedEvent(let value):
            try container.encode(value)
        case .typeCallEndedEvent(let value):
            try container.encode(value)
        case .typeCallHLSBroadcastingFailedEvent(let value):
            try container.encode(value)
        case .typeCallHLSBroadcastingStartedEvent(let value):
            try container.encode(value)
        case .typeCallHLSBroadcastingStoppedEvent(let value):
            try container.encode(value)
        case .typeCallLiveStartedEvent(let value):
            try container.encode(value)
        case .typeCallMemberAddedEvent(let value):
            try container.encode(value)
        case .typeCallMemberRemovedEvent(let value):
            try container.encode(value)
        case .typeCallMemberUpdatedEvent(let value):
            try container.encode(value)
        case .typeCallMemberUpdatedPermissionEvent(let value):
            try container.encode(value)
        case .typeCallNotificationEvent(let value):
            try container.encode(value)
        case .typeCallReactionEvent(let value):
            try container.encode(value)
        case .typeCallRecordingFailedEvent(let value):
            try container.encode(value)
        case .typeCallRecordingReadyEvent(let value):
            try container.encode(value)
        case .typeCallRecordingStartedEvent(let value):
            try container.encode(value)
        case .typeCallRecordingStoppedEvent(let value):
            try container.encode(value)
        case .typeCallRejectedEvent(let value):
            try container.encode(value)
        case .typeCallRingEvent(let value):
            try container.encode(value)
        case .typeCallSessionEndedEvent(let value):
            try container.encode(value)
        case .typeCallSessionParticipantJoinedEvent(let value):
            try container.encode(value)
        case .typeCallSessionParticipantLeftEvent(let value):
            try container.encode(value)
        case .typeCallSessionStartedEvent(let value):
            try container.encode(value)
        case .typeCallTranscriptionFailedEvent(let value):
            try container.encode(value)
        case .typeCallTranscriptionReadyEvent(let value):
            try container.encode(value)
        case .typeCallTranscriptionStartedEvent(let value):
            try container.encode(value)
        case .typeCallTranscriptionStoppedEvent(let value):
            try container.encode(value)
        case .typeCallUpdatedEvent(let value):
            try container.encode(value)
        case .typeCallUserMutedEvent(let value):
            try container.encode(value)
        case .typeClosedCaptionEvent(let value):
            try container.encode(value)
        case .typeConnectedEvent(let value):
            try container.encode(value)
        case .typeConnectionErrorEvent(let value):
            try container.encode(value)
        case .typeCustomVideoEvent(let value):
            try container.encode(value)
        case .typeHealthCheckEvent(let value):
            try container.encode(value)
        case .typePermissionRequestEvent(let value):
            try container.encode(value)
        case .typeUnblockedUserEvent(let value):
            try container.encode(value)
        case .typeUpdatedCallPermissionsEvent(let value):
            try container.encode(value)
        case .typeUserBannedEvent(let value):
            try container.encode(value)
        case .typeUserDeactivatedEvent(let value):
            try container.encode(value)
        case .typeUserDeletedEvent(let value):
            try container.encode(value)
        case .typeUserMutedEvent(let value):
            try container.encode(value)
        case .typeUserPresenceChangedEvent(let value):
            try container.encode(value)
        case .typeUserReactivatedEvent(let value):
            try container.encode(value)
        case .typeUserUnbannedEvent(let value):
            try container.encode(value)
        case .typeUserUpdatedEvent(let value):
            try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dto = try container.decode(WSEventMapping.self)
        if dto.type == "call.accepted" {
            let value = try container.decode(CallAcceptedEvent.self)
            self = .typeCallAcceptedEvent(value)
        } else if dto.type == "call.blocked_user" {
            let value = try container.decode(BlockedUserEvent.self)
            self = .typeBlockedUserEvent(value)
        } else if dto.type == "call.closed_caption" {
            let value = try container.decode(ClosedCaptionEvent.self)
            self = .typeClosedCaptionEvent(value)
        } else if dto.type == "call.created" {
            let value = try container.decode(CallCreatedEvent.self)
            self = .typeCallCreatedEvent(value)
        } else if dto.type == "call.deleted" {
            let value = try container.decode(CallDeletedEvent.self)
            self = .typeCallDeletedEvent(value)
        } else if dto.type == "call.ended" {
            let value = try container.decode(CallEndedEvent.self)
            self = .typeCallEndedEvent(value)
        } else if dto.type == "call.hls_broadcasting_failed" {
            let value = try container.decode(CallHLSBroadcastingFailedEvent.self)
            self = .typeCallHLSBroadcastingFailedEvent(value)
        } else if dto.type == "call.hls_broadcasting_started" {
            let value = try container.decode(CallHLSBroadcastingStartedEvent.self)
            self = .typeCallHLSBroadcastingStartedEvent(value)
        } else if dto.type == "call.hls_broadcasting_stopped" {
            let value = try container.decode(CallHLSBroadcastingStoppedEvent.self)
            self = .typeCallHLSBroadcastingStoppedEvent(value)
        } else if dto.type == "call.live_started" {
            let value = try container.decode(CallLiveStartedEvent.self)
            self = .typeCallLiveStartedEvent(value)
        } else if dto.type == "call.member_added" {
            let value = try container.decode(CallMemberAddedEvent.self)
            self = .typeCallMemberAddedEvent(value)
        } else if dto.type == "call.member_removed" {
            let value = try container.decode(CallMemberRemovedEvent.self)
            self = .typeCallMemberRemovedEvent(value)
        } else if dto.type == "call.member_updated" {
            let value = try container.decode(CallMemberUpdatedEvent.self)
            self = .typeCallMemberUpdatedEvent(value)
        } else if dto.type == "call.member_updated_permission" {
            let value = try container.decode(CallMemberUpdatedPermissionEvent.self)
            self = .typeCallMemberUpdatedPermissionEvent(value)
        } else if dto.type == "call.notification" {
            let value = try container.decode(CallNotificationEvent.self)
            self = .typeCallNotificationEvent(value)
        } else if dto.type == "call.permission_request" {
            let value = try container.decode(PermissionRequestEvent.self)
            self = .typePermissionRequestEvent(value)
        } else if dto.type == "call.permissions_updated" {
            let value = try container.decode(UpdatedCallPermissionsEvent.self)
            self = .typeUpdatedCallPermissionsEvent(value)
        } else if dto.type == "call.reaction_new" {
            let value = try container.decode(CallReactionEvent.self)
            self = .typeCallReactionEvent(value)
        } else if dto.type == "call.recording_failed" {
            let value = try container.decode(CallRecordingFailedEvent.self)
            self = .typeCallRecordingFailedEvent(value)
        } else if dto.type == "call.recording_ready" {
            let value = try container.decode(CallRecordingReadyEvent.self)
            self = .typeCallRecordingReadyEvent(value)
        } else if dto.type == "call.recording_started" {
            let value = try container.decode(CallRecordingStartedEvent.self)
            self = .typeCallRecordingStartedEvent(value)
        } else if dto.type == "call.recording_stopped" {
            let value = try container.decode(CallRecordingStoppedEvent.self)
            self = .typeCallRecordingStoppedEvent(value)
        } else if dto.type == "call.rejected" {
            let value = try container.decode(CallRejectedEvent.self)
            self = .typeCallRejectedEvent(value)
        } else if dto.type == "call.ring" {
            let value = try container.decode(CallRingEvent.self)
            self = .typeCallRingEvent(value)
        } else if dto.type == "call.session_ended" {
            let value = try container.decode(CallSessionEndedEvent.self)
            self = .typeCallSessionEndedEvent(value)
        } else if dto.type == "call.session_participant_joined" {
            let value = try container.decode(CallSessionParticipantJoinedEvent.self)
            self = .typeCallSessionParticipantJoinedEvent(value)
        } else if dto.type == "call.session_participant_left" {
            let value = try container.decode(CallSessionParticipantLeftEvent.self)
            self = .typeCallSessionParticipantLeftEvent(value)
        } else if dto.type == "call.session_started" {
            let value = try container.decode(CallSessionStartedEvent.self)
            self = .typeCallSessionStartedEvent(value)
        } else if dto.type == "call.transcription_failed" {
            let value = try container.decode(CallTranscriptionFailedEvent.self)
            self = .typeCallTranscriptionFailedEvent(value)
        } else if dto.type == "call.transcription_ready" {
            let value = try container.decode(CallTranscriptionReadyEvent.self)
            self = .typeCallTranscriptionReadyEvent(value)
        } else if dto.type == "call.transcription_started" {
            let value = try container.decode(CallTranscriptionStartedEvent.self)
            self = .typeCallTranscriptionStartedEvent(value)
        } else if dto.type == "call.transcription_stopped" {
            let value = try container.decode(CallTranscriptionStoppedEvent.self)
            self = .typeCallTranscriptionStoppedEvent(value)
        } else if dto.type == "call.unblocked_user" {
            let value = try container.decode(UnblockedUserEvent.self)
            self = .typeUnblockedUserEvent(value)
        } else if dto.type == "call.updated" {
            let value = try container.decode(CallUpdatedEvent.self)
            self = .typeCallUpdatedEvent(value)
        } else if dto.type == "call.user_muted" {
            let value = try container.decode(CallUserMutedEvent.self)
            self = .typeCallUserMutedEvent(value)
        } else if dto.type == "connection.error" {
            let value = try container.decode(ConnectionErrorEvent.self)
            self = .typeConnectionErrorEvent(value)
        } else if dto.type == "connection.ok" {
            let value = try container.decode(ConnectedEvent.self)
            self = .typeConnectedEvent(value)
        } else if dto.type == "custom" {
            let value = try container.decode(CustomVideoEvent.self)
            self = .typeCustomVideoEvent(value)
        } else if dto.type == "health.check" {
            let value = try container.decode(HealthCheckEvent.self)
            self = .typeHealthCheckEvent(value)
        } else if dto.type == "user.banned" {
            let value = try container.decode(UserBannedEvent.self)
            self = .typeUserBannedEvent(value)
        } else if dto.type == "user.deactivated" {
            let value = try container.decode(UserDeactivatedEvent.self)
            self = .typeUserDeactivatedEvent(value)
        } else if dto.type == "user.deleted" {
            let value = try container.decode(UserDeletedEvent.self)
            self = .typeUserDeletedEvent(value)
        } else if dto.type == "user.muted" {
            let value = try container.decode(UserMutedEvent.self)
            self = .typeUserMutedEvent(value)
        } else if dto.type == "user.presence.changed" {
            let value = try container.decode(UserPresenceChangedEvent.self)
            self = .typeUserPresenceChangedEvent(value)
        } else if dto.type == "user.reactivated" {
            let value = try container.decode(UserReactivatedEvent.self)
            self = .typeUserReactivatedEvent(value)
        } else if dto.type == "user.unbanned" {
            let value = try container.decode(UserUnbannedEvent.self)
            self = .typeUserUnbannedEvent(value)
        } else if dto.type == "user.updated" {
            let value = try container.decode(UserUpdatedEvent.self)
            self = .typeUserUpdatedEvent(value)
        } else {
            throw DecodingError.typeMismatch(Self.Type.self, .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of WSEvent"))
        }
    }

}

