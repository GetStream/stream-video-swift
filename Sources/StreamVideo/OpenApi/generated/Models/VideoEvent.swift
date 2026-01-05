//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

internal protocol WSCallEvent {
    var callCid: String { get }
}

private class WSEventMapping: Decodable {
    let type: String
}

public enum VideoEvent: Codable, Hashable {
    case typeAppUpdatedEvent(AppUpdatedEvent)
    case typeCallAcceptedEvent(CallAcceptedEvent)
    case typeBlockedUserEvent(BlockedUserEvent)
    case typeClosedCaptionEvent(ClosedCaptionEvent)
    case typeCallClosedCaptionsFailedEvent(CallClosedCaptionsFailedEvent)
    case typeCallClosedCaptionsStartedEvent(CallClosedCaptionsStartedEvent)
    case typeCallClosedCaptionsStoppedEvent(CallClosedCaptionsStoppedEvent)
    case typeCallCreatedEvent(CallCreatedEvent)
    case typeCallDeletedEvent(CallDeletedEvent)
    case typeCallEndedEvent(CallEndedEvent)
    case typeCallFrameRecordingFailedEvent(CallFrameRecordingFailedEvent)
    case typeCallFrameRecordingFrameReadyEvent(CallFrameRecordingFrameReadyEvent)
    case typeCallFrameRecordingStartedEvent(CallFrameRecordingStartedEvent)
    case typeCallFrameRecordingStoppedEvent(CallFrameRecordingStoppedEvent)
    case typeCallHLSBroadcastingFailedEvent(CallHLSBroadcastingFailedEvent)
    case typeCallHLSBroadcastingStartedEvent(CallHLSBroadcastingStartedEvent)
    case typeCallHLSBroadcastingStoppedEvent(CallHLSBroadcastingStoppedEvent)
    case typeKickedUserEvent(KickedUserEvent)
    case typeCallLiveStartedEvent(CallLiveStartedEvent)
    case typeCallMemberAddedEvent(CallMemberAddedEvent)
    case typeCallMemberRemovedEvent(CallMemberRemovedEvent)
    case typeCallMemberUpdatedEvent(CallMemberUpdatedEvent)
    case typeCallMemberUpdatedPermissionEvent(CallMemberUpdatedPermissionEvent)
    case typeCallMissedEvent(CallMissedEvent)
    case typeCallModerationBlurEvent(CallModerationBlurEvent)
    case typeCallModerationWarningEvent(CallModerationWarningEvent)
    case typeCallNotificationEvent(CallNotificationEvent)
    case typePermissionRequestEvent(PermissionRequestEvent)
    case typeUpdatedCallPermissionsEvent(UpdatedCallPermissionsEvent)
    case typeCallReactionEvent(CallReactionEvent)
    case typeCallRecordingFailedEvent(CallRecordingFailedEvent)
    case typeCallRecordingReadyEvent(CallRecordingReadyEvent)
    case typeCallRecordingStartedEvent(CallRecordingStartedEvent)
    case typeCallRecordingStoppedEvent(CallRecordingStoppedEvent)
    case typeCallRejectedEvent(CallRejectedEvent)
    case typeCallRingEvent(CallRingEvent)
    case typeCallRtmpBroadcastFailedEvent(CallRtmpBroadcastFailedEvent)
    case typeCallRtmpBroadcastStartedEvent(CallRtmpBroadcastStartedEvent)
    case typeCallRtmpBroadcastStoppedEvent(CallRtmpBroadcastStoppedEvent)
    case typeCallSessionEndedEvent(CallSessionEndedEvent)
    case typeCallSessionParticipantCountsUpdatedEvent(CallSessionParticipantCountsUpdatedEvent)
    case typeCallSessionParticipantJoinedEvent(CallSessionParticipantJoinedEvent)
    case typeCallSessionParticipantLeftEvent(CallSessionParticipantLeftEvent)
    case typeCallSessionStartedEvent(CallSessionStartedEvent)
    case typeCallStatsReportReadyEvent(CallStatsReportReadyEvent)
    case typeCallTranscriptionFailedEvent(CallTranscriptionFailedEvent)
    case typeCallTranscriptionReadyEvent(CallTranscriptionReadyEvent)
    case typeCallTranscriptionStartedEvent(CallTranscriptionStartedEvent)
    case typeCallTranscriptionStoppedEvent(CallTranscriptionStoppedEvent)
    case typeUnblockedUserEvent(UnblockedUserEvent)
    case typeCallUpdatedEvent(CallUpdatedEvent)
    case typeCallUserFeedbackSubmittedEvent(CallUserFeedbackSubmittedEvent)
    case typeCallUserMutedEvent(CallUserMutedEvent)
    case typeConnectionErrorEvent(ConnectionErrorEvent)
    case typeConnectedEvent(ConnectedEvent)
    case typeCustomVideoEvent(CustomVideoEvent)
    case typeHealthCheckEvent(HealthCheckEvent)
    case typeUserUpdatedEvent(UserUpdatedEvent)

    public var type: String {
        switch self {
        case let .typeAppUpdatedEvent(value):
            return value.type
        case let .typeCallAcceptedEvent(value):
            return value.type
        case let .typeBlockedUserEvent(value):
            return value.type
        case let .typeClosedCaptionEvent(value):
            return value.type
        case let .typeCallClosedCaptionsFailedEvent(value):
            return value.type
        case let .typeCallClosedCaptionsStartedEvent(value):
            return value.type
        case let .typeCallClosedCaptionsStoppedEvent(value):
            return value.type
        case let .typeCallCreatedEvent(value):
            return value.type
        case let .typeCallDeletedEvent(value):
            return value.type
        case let .typeCallEndedEvent(value):
            return value.type
        case let .typeCallFrameRecordingFailedEvent(value):
            return value.type
        case let .typeCallFrameRecordingFrameReadyEvent(value):
            return value.type
        case let .typeCallFrameRecordingStartedEvent(value):
            return value.type
        case let .typeCallFrameRecordingStoppedEvent(value):
            return value.type
        case let .typeCallHLSBroadcastingFailedEvent(value):
            return value.type
        case let .typeCallHLSBroadcastingStartedEvent(value):
            return value.type
        case let .typeCallHLSBroadcastingStoppedEvent(value):
            return value.type
        case let .typeKickedUserEvent(value):
            return value.type
        case let .typeCallLiveStartedEvent(value):
            return value.type
        case let .typeCallMemberAddedEvent(value):
            return value.type
        case let .typeCallMemberRemovedEvent(value):
            return value.type
        case let .typeCallMemberUpdatedEvent(value):
            return value.type
        case let .typeCallMemberUpdatedPermissionEvent(value):
            return value.type
        case let .typeCallMissedEvent(value):
            return value.type
        case let .typeCallModerationBlurEvent(value):
            return value.type
        case let .typeCallModerationWarningEvent(value):
            return value.type
        case let .typeCallNotificationEvent(value):
            return value.type
        case let .typePermissionRequestEvent(value):
            return value.type
        case let .typeUpdatedCallPermissionsEvent(value):
            return value.type
        case let .typeCallReactionEvent(value):
            return value.type
        case let .typeCallRecordingFailedEvent(value):
            return value.type
        case let .typeCallRecordingReadyEvent(value):
            return value.type
        case let .typeCallRecordingStartedEvent(value):
            return value.type
        case let .typeCallRecordingStoppedEvent(value):
            return value.type
        case let .typeCallRejectedEvent(value):
            return value.type
        case let .typeCallRingEvent(value):
            return value.type
        case let .typeCallRtmpBroadcastFailedEvent(value):
            return value.type
        case let .typeCallRtmpBroadcastStartedEvent(value):
            return value.type
        case let .typeCallRtmpBroadcastStoppedEvent(value):
            return value.type
        case let .typeCallSessionEndedEvent(value):
            return value.type
        case let .typeCallSessionParticipantCountsUpdatedEvent(value):
            return value.type
        case let .typeCallSessionParticipantJoinedEvent(value):
            return value.type
        case let .typeCallSessionParticipantLeftEvent(value):
            return value.type
        case let .typeCallSessionStartedEvent(value):
            return value.type
        case let .typeCallStatsReportReadyEvent(value):
            return value.type
        case let .typeCallTranscriptionFailedEvent(value):
            return value.type
        case let .typeCallTranscriptionReadyEvent(value):
            return value.type
        case let .typeCallTranscriptionStartedEvent(value):
            return value.type
        case let .typeCallTranscriptionStoppedEvent(value):
            return value.type
        case let .typeUnblockedUserEvent(value):
            return value.type
        case let .typeCallUpdatedEvent(value):
            return value.type
        case let .typeCallUserFeedbackSubmittedEvent(value):
            return value.type
        case let .typeCallUserMutedEvent(value):
            return value.type
        case let .typeConnectionErrorEvent(value):
            return value.type
        case let .typeConnectedEvent(value):
            return value.type
        case let .typeCustomVideoEvent(value):
            return value.type
        case let .typeHealthCheckEvent(value):
            return value.type
        case let .typeUserUpdatedEvent(value):
            return value.type
        }
    }

    public var rawValue: Event {
        switch self {
        case let .typeAppUpdatedEvent(value):
            return value
        case let .typeCallAcceptedEvent(value):
            return value
        case let .typeBlockedUserEvent(value):
            return value
        case let .typeClosedCaptionEvent(value):
            return value
        case let .typeCallClosedCaptionsFailedEvent(value):
            return value
        case let .typeCallClosedCaptionsStartedEvent(value):
            return value
        case let .typeCallClosedCaptionsStoppedEvent(value):
            return value
        case let .typeCallCreatedEvent(value):
            return value
        case let .typeCallDeletedEvent(value):
            return value
        case let .typeCallEndedEvent(value):
            return value
        case let .typeCallFrameRecordingFailedEvent(value):
            return value
        case let .typeCallFrameRecordingFrameReadyEvent(value):
            return value
        case let .typeCallFrameRecordingStartedEvent(value):
            return value
        case let .typeCallFrameRecordingStoppedEvent(value):
            return value
        case let .typeCallHLSBroadcastingFailedEvent(value):
            return value
        case let .typeCallHLSBroadcastingStartedEvent(value):
            return value
        case let .typeCallHLSBroadcastingStoppedEvent(value):
            return value
        case let .typeKickedUserEvent(value):
            return value
        case let .typeCallLiveStartedEvent(value):
            return value
        case let .typeCallMemberAddedEvent(value):
            return value
        case let .typeCallMemberRemovedEvent(value):
            return value
        case let .typeCallMemberUpdatedEvent(value):
            return value
        case let .typeCallMemberUpdatedPermissionEvent(value):
            return value
        case let .typeCallMissedEvent(value):
            return value
        case let .typeCallModerationBlurEvent(value):
            return value
        case let .typeCallModerationWarningEvent(value):
            return value
        case let .typeCallNotificationEvent(value):
            return value
        case let .typePermissionRequestEvent(value):
            return value
        case let .typeUpdatedCallPermissionsEvent(value):
            return value
        case let .typeCallReactionEvent(value):
            return value
        case let .typeCallRecordingFailedEvent(value):
            return value
        case let .typeCallRecordingReadyEvent(value):
            return value
        case let .typeCallRecordingStartedEvent(value):
            return value
        case let .typeCallRecordingStoppedEvent(value):
            return value
        case let .typeCallRejectedEvent(value):
            return value
        case let .typeCallRingEvent(value):
            return value
        case let .typeCallRtmpBroadcastFailedEvent(value):
            return value
        case let .typeCallRtmpBroadcastStartedEvent(value):
            return value
        case let .typeCallRtmpBroadcastStoppedEvent(value):
            return value
        case let .typeCallSessionEndedEvent(value):
            return value
        case let .typeCallSessionParticipantCountsUpdatedEvent(value):
            return value
        case let .typeCallSessionParticipantJoinedEvent(value):
            return value
        case let .typeCallSessionParticipantLeftEvent(value):
            return value
        case let .typeCallSessionStartedEvent(value):
            return value
        case let .typeCallStatsReportReadyEvent(value):
            return value
        case let .typeCallTranscriptionFailedEvent(value):
            return value
        case let .typeCallTranscriptionReadyEvent(value):
            return value
        case let .typeCallTranscriptionStartedEvent(value):
            return value
        case let .typeCallTranscriptionStoppedEvent(value):
            return value
        case let .typeUnblockedUserEvent(value):
            return value
        case let .typeCallUpdatedEvent(value):
            return value
        case let .typeCallUserFeedbackSubmittedEvent(value):
            return value
        case let .typeCallUserMutedEvent(value):
            return value
        case let .typeConnectionErrorEvent(value):
            return value
        case let .typeConnectedEvent(value):
            return value
        case let .typeCustomVideoEvent(value):
            return value
        case let .typeHealthCheckEvent(value):
            return value
        case let .typeUserUpdatedEvent(value):
            return value
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .typeAppUpdatedEvent(value):
            try container.encode(value)
        case let .typeCallAcceptedEvent(value):
            try container.encode(value)
        case let .typeBlockedUserEvent(value):
            try container.encode(value)
        case let .typeClosedCaptionEvent(value):
            try container.encode(value)
        case let .typeCallClosedCaptionsFailedEvent(value):
            try container.encode(value)
        case let .typeCallClosedCaptionsStartedEvent(value):
            try container.encode(value)
        case let .typeCallClosedCaptionsStoppedEvent(value):
            try container.encode(value)
        case let .typeCallCreatedEvent(value):
            try container.encode(value)
        case let .typeCallDeletedEvent(value):
            try container.encode(value)
        case let .typeCallEndedEvent(value):
            try container.encode(value)
        case let .typeCallFrameRecordingFailedEvent(value):
            try container.encode(value)
        case let .typeCallFrameRecordingFrameReadyEvent(value):
            try container.encode(value)
        case let .typeCallFrameRecordingStartedEvent(value):
            try container.encode(value)
        case let .typeCallFrameRecordingStoppedEvent(value):
            try container.encode(value)
        case let .typeCallHLSBroadcastingFailedEvent(value):
            try container.encode(value)
        case let .typeCallHLSBroadcastingStartedEvent(value):
            try container.encode(value)
        case let .typeCallHLSBroadcastingStoppedEvent(value):
            try container.encode(value)
        case let .typeKickedUserEvent(value):
            try container.encode(value)
        case let .typeCallLiveStartedEvent(value):
            try container.encode(value)
        case let .typeCallMemberAddedEvent(value):
            try container.encode(value)
        case let .typeCallMemberRemovedEvent(value):
            try container.encode(value)
        case let .typeCallMemberUpdatedEvent(value):
            try container.encode(value)
        case let .typeCallMemberUpdatedPermissionEvent(value):
            try container.encode(value)
        case let .typeCallMissedEvent(value):
            try container.encode(value)
        case let .typeCallModerationBlurEvent(value):
            try container.encode(value)
        case let .typeCallModerationWarningEvent(value):
            try container.encode(value)
        case let .typeCallNotificationEvent(value):
            try container.encode(value)
        case let .typePermissionRequestEvent(value):
            try container.encode(value)
        case let .typeUpdatedCallPermissionsEvent(value):
            try container.encode(value)
        case let .typeCallReactionEvent(value):
            try container.encode(value)
        case let .typeCallRecordingFailedEvent(value):
            try container.encode(value)
        case let .typeCallRecordingReadyEvent(value):
            try container.encode(value)
        case let .typeCallRecordingStartedEvent(value):
            try container.encode(value)
        case let .typeCallRecordingStoppedEvent(value):
            try container.encode(value)
        case let .typeCallRejectedEvent(value):
            try container.encode(value)
        case let .typeCallRingEvent(value):
            try container.encode(value)
        case let .typeCallRtmpBroadcastFailedEvent(value):
            try container.encode(value)
        case let .typeCallRtmpBroadcastStartedEvent(value):
            try container.encode(value)
        case let .typeCallRtmpBroadcastStoppedEvent(value):
            try container.encode(value)
        case let .typeCallSessionEndedEvent(value):
            try container.encode(value)
        case let .typeCallSessionParticipantCountsUpdatedEvent(value):
            try container.encode(value)
        case let .typeCallSessionParticipantJoinedEvent(value):
            try container.encode(value)
        case let .typeCallSessionParticipantLeftEvent(value):
            try container.encode(value)
        case let .typeCallSessionStartedEvent(value):
            try container.encode(value)
        case let .typeCallStatsReportReadyEvent(value):
            try container.encode(value)
        case let .typeCallTranscriptionFailedEvent(value):
            try container.encode(value)
        case let .typeCallTranscriptionReadyEvent(value):
            try container.encode(value)
        case let .typeCallTranscriptionStartedEvent(value):
            try container.encode(value)
        case let .typeCallTranscriptionStoppedEvent(value):
            try container.encode(value)
        case let .typeUnblockedUserEvent(value):
            try container.encode(value)
        case let .typeCallUpdatedEvent(value):
            try container.encode(value)
        case let .typeCallUserFeedbackSubmittedEvent(value):
            try container.encode(value)
        case let .typeCallUserMutedEvent(value):
            try container.encode(value)
        case let .typeConnectionErrorEvent(value):
            try container.encode(value)
        case let .typeConnectedEvent(value):
            try container.encode(value)
        case let .typeCustomVideoEvent(value):
            try container.encode(value)
        case let .typeHealthCheckEvent(value):
            try container.encode(value)
        case let .typeUserUpdatedEvent(value):
            try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dto = try container.decode(WSEventMapping.self)
        if dto.type == "app.updated" {
            let value = try container.decode(AppUpdatedEvent.self)
            self = .typeAppUpdatedEvent(value)
        } else if dto.type == "call.accepted" {
            let value = try container.decode(CallAcceptedEvent.self)
            self = .typeCallAcceptedEvent(value)
        } else if dto.type == "call.blocked_user" {
            let value = try container.decode(BlockedUserEvent.self)
            self = .typeBlockedUserEvent(value)
        } else if dto.type == "call.closed_caption" {
            let value = try container.decode(ClosedCaptionEvent.self)
            self = .typeClosedCaptionEvent(value)
        } else if dto.type == "call.closed_captions_failed" {
            let value = try container.decode(CallClosedCaptionsFailedEvent.self)
            self = .typeCallClosedCaptionsFailedEvent(value)
        } else if dto.type == "call.closed_captions_started" {
            let value = try container.decode(CallClosedCaptionsStartedEvent.self)
            self = .typeCallClosedCaptionsStartedEvent(value)
        } else if dto.type == "call.closed_captions_stopped" {
            let value = try container.decode(CallClosedCaptionsStoppedEvent.self)
            self = .typeCallClosedCaptionsStoppedEvent(value)
        } else if dto.type == "call.created" {
            let value = try container.decode(CallCreatedEvent.self)
            self = .typeCallCreatedEvent(value)
        } else if dto.type == "call.deleted" {
            let value = try container.decode(CallDeletedEvent.self)
            self = .typeCallDeletedEvent(value)
        } else if dto.type == "call.ended" {
            let value = try container.decode(CallEndedEvent.self)
            self = .typeCallEndedEvent(value)
        } else if dto.type == "call.frame_recording_failed" {
            let value = try container.decode(CallFrameRecordingFailedEvent.self)
            self = .typeCallFrameRecordingFailedEvent(value)
        } else if dto.type == "call.frame_recording_ready" {
            let value = try container.decode(CallFrameRecordingFrameReadyEvent.self)
            self = .typeCallFrameRecordingFrameReadyEvent(value)
        } else if dto.type == "call.frame_recording_started" {
            let value = try container.decode(CallFrameRecordingStartedEvent.self)
            self = .typeCallFrameRecordingStartedEvent(value)
        } else if dto.type == "call.frame_recording_stopped" {
            let value = try container.decode(CallFrameRecordingStoppedEvent.self)
            self = .typeCallFrameRecordingStoppedEvent(value)
        } else if dto.type == "call.hls_broadcasting_failed" {
            let value = try container.decode(CallHLSBroadcastingFailedEvent.self)
            self = .typeCallHLSBroadcastingFailedEvent(value)
        } else if dto.type == "call.hls_broadcasting_started" {
            let value = try container.decode(CallHLSBroadcastingStartedEvent.self)
            self = .typeCallHLSBroadcastingStartedEvent(value)
        } else if dto.type == "call.hls_broadcasting_stopped" {
            let value = try container.decode(CallHLSBroadcastingStoppedEvent.self)
            self = .typeCallHLSBroadcastingStoppedEvent(value)
        } else if dto.type == "call.kicked_user" {
            let value = try container.decode(KickedUserEvent.self)
            self = .typeKickedUserEvent(value)
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
        } else if dto.type == "call.missed" {
            let value = try container.decode(CallMissedEvent.self)
            self = .typeCallMissedEvent(value)
        } else if dto.type == "call.moderation_blur" {
            let value = try container.decode(CallModerationBlurEvent.self)
            self = .typeCallModerationBlurEvent(value)
        } else if dto.type == "call.moderation_warning" {
            let value = try container.decode(CallModerationWarningEvent.self)
            self = .typeCallModerationWarningEvent(value)
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
        } else if dto.type == "call.rtmp_broadcast_failed" {
            let value = try container.decode(CallRtmpBroadcastFailedEvent.self)
            self = .typeCallRtmpBroadcastFailedEvent(value)
        } else if dto.type == "call.rtmp_broadcast_started" {
            let value = try container.decode(CallRtmpBroadcastStartedEvent.self)
            self = .typeCallRtmpBroadcastStartedEvent(value)
        } else if dto.type == "call.rtmp_broadcast_stopped" {
            let value = try container.decode(CallRtmpBroadcastStoppedEvent.self)
            self = .typeCallRtmpBroadcastStoppedEvent(value)
        } else if dto.type == "call.session_ended" {
            let value = try container.decode(CallSessionEndedEvent.self)
            self = .typeCallSessionEndedEvent(value)
        } else if dto.type == "call.session_participant_count_updated" {
            let value = try container.decode(CallSessionParticipantCountsUpdatedEvent.self)
            self = .typeCallSessionParticipantCountsUpdatedEvent(value)
        } else if dto.type == "call.session_participant_joined" {
            let value = try container.decode(CallSessionParticipantJoinedEvent.self)
            self = .typeCallSessionParticipantJoinedEvent(value)
        } else if dto.type == "call.session_participant_left" {
            let value = try container.decode(CallSessionParticipantLeftEvent.self)
            self = .typeCallSessionParticipantLeftEvent(value)
        } else if dto.type == "call.session_started" {
            let value = try container.decode(CallSessionStartedEvent.self)
            self = .typeCallSessionStartedEvent(value)
        } else if dto.type == "call.stats_report_ready" {
            let value = try container.decode(CallStatsReportReadyEvent.self)
            self = .typeCallStatsReportReadyEvent(value)
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
        } else if dto.type == "call.user_feedback_submitted" {
            let value = try container.decode(CallUserFeedbackSubmittedEvent.self)
            self = .typeCallUserFeedbackSubmittedEvent(value)
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
        } else if dto.type == "user.updated" {
            let value = try container.decode(UserUpdatedEvent.self)
            self = .typeUserUpdatedEvent(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.Type.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of VideoEvent")
            )
        }
    }
}
