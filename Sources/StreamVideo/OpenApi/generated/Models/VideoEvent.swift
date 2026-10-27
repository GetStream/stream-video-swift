//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

internal protocol WSCallEvent {
    var callCid: String { get }
}

private class WSEventMapping: Decodable {
    let type: String
}

public enum VideoEvent: Decodable, Hashable {
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
        case .typeAppUpdatedEvent(let value):
            return value.type
        case .typeCallAcceptedEvent(let value):
            return value.type
        case .typeBlockedUserEvent(let value):
            return value.type
        case .typeClosedCaptionEvent(let value):
            return value.type
        case .typeCallClosedCaptionsFailedEvent(let value):
            return value.type
        case .typeCallClosedCaptionsStartedEvent(let value):
            return value.type
        case .typeCallClosedCaptionsStoppedEvent(let value):
            return value.type
        case .typeCallCreatedEvent(let value):
            return value.type
        case .typeCallDeletedEvent(let value):
            return value.type
        case .typeCallEndedEvent(let value):
            return value.type
        case .typeCallFrameRecordingFailedEvent(let value):
            return value.type
        case .typeCallFrameRecordingFrameReadyEvent(let value):
            return value.type
        case .typeCallFrameRecordingStartedEvent(let value):
            return value.type
        case .typeCallFrameRecordingStoppedEvent(let value):
            return value.type
        case .typeCallHLSBroadcastingFailedEvent(let value):
            return value.type
        case .typeCallHLSBroadcastingStartedEvent(let value):
            return value.type
        case .typeCallHLSBroadcastingStoppedEvent(let value):
            return value.type
        case .typeKickedUserEvent(let value):
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
        case .typeCallMissedEvent(let value):
            return value.type
        case .typeCallModerationBlurEvent(let value):
            return value.type
        case .typeCallModerationWarningEvent(let value):
            return value.type
        case .typeCallNotificationEvent(let value):
            return value.type
        case .typePermissionRequestEvent(let value):
            return value.type
        case .typeUpdatedCallPermissionsEvent(let value):
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
        case .typeCallRtmpBroadcastFailedEvent(let value):
            return value.type
        case .typeCallRtmpBroadcastStartedEvent(let value):
            return value.type
        case .typeCallRtmpBroadcastStoppedEvent(let value):
            return value.type
        case .typeCallSessionEndedEvent(let value):
            return value.type
        case .typeCallSessionParticipantCountsUpdatedEvent(let value):
            return value.type
        case .typeCallSessionParticipantJoinedEvent(let value):
            return value.type
        case .typeCallSessionParticipantLeftEvent(let value):
            return value.type
        case .typeCallSessionStartedEvent(let value):
            return value.type
        case .typeCallStatsReportReadyEvent(let value):
            return value.type
        case .typeCallTranscriptionFailedEvent(let value):
            return value.type
        case .typeCallTranscriptionReadyEvent(let value):
            return value.type
        case .typeCallTranscriptionStartedEvent(let value):
            return value.type
        case .typeCallTranscriptionStoppedEvent(let value):
            return value.type
        case .typeUnblockedUserEvent(let value):
            return value.type
        case .typeCallUpdatedEvent(let value):
            return value.type
        case .typeCallUserFeedbackSubmittedEvent(let value):
            return value.type
        case .typeCallUserMutedEvent(let value):
            return value.type
        case .typeConnectionErrorEvent(let value):
            return value.type
        case .typeConnectedEvent(let value):
            return value.type
        case .typeCustomVideoEvent(let value):
            return value.type
        case .typeHealthCheckEvent(let value):
            return value.type
        case .typeUserUpdatedEvent(let value):
            return value.type
        }
    }

    public var rawValue: Event {
        switch self {
        case .typeAppUpdatedEvent(let value):
            return value
        case .typeCallAcceptedEvent(let value):
            return value
        case .typeBlockedUserEvent(let value):
            return value
        case .typeClosedCaptionEvent(let value):
            return value
        case .typeCallClosedCaptionsFailedEvent(let value):
            return value
        case .typeCallClosedCaptionsStartedEvent(let value):
            return value
        case .typeCallClosedCaptionsStoppedEvent(let value):
            return value
        case .typeCallCreatedEvent(let value):
            return value
        case .typeCallDeletedEvent(let value):
            return value
        case .typeCallEndedEvent(let value):
            return value
        case .typeCallFrameRecordingFailedEvent(let value):
            return value
        case .typeCallFrameRecordingFrameReadyEvent(let value):
            return value
        case .typeCallFrameRecordingStartedEvent(let value):
            return value
        case .typeCallFrameRecordingStoppedEvent(let value):
            return value
        case .typeCallHLSBroadcastingFailedEvent(let value):
            return value
        case .typeCallHLSBroadcastingStartedEvent(let value):
            return value
        case .typeCallHLSBroadcastingStoppedEvent(let value):
            return value
        case .typeKickedUserEvent(let value):
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
        case .typeCallMissedEvent(let value):
            return value
        case .typeCallModerationBlurEvent(let value):
            return value
        case .typeCallModerationWarningEvent(let value):
            return value
        case .typeCallNotificationEvent(let value):
            return value
        case .typePermissionRequestEvent(let value):
            return value
        case .typeUpdatedCallPermissionsEvent(let value):
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
        case .typeCallRtmpBroadcastFailedEvent(let value):
            return value
        case .typeCallRtmpBroadcastStartedEvent(let value):
            return value
        case .typeCallRtmpBroadcastStoppedEvent(let value):
            return value
        case .typeCallSessionEndedEvent(let value):
            return value
        case .typeCallSessionParticipantCountsUpdatedEvent(let value):
            return value
        case .typeCallSessionParticipantJoinedEvent(let value):
            return value
        case .typeCallSessionParticipantLeftEvent(let value):
            return value
        case .typeCallSessionStartedEvent(let value):
            return value
        case .typeCallStatsReportReadyEvent(let value):
            return value
        case .typeCallTranscriptionFailedEvent(let value):
            return value
        case .typeCallTranscriptionReadyEvent(let value):
            return value
        case .typeCallTranscriptionStartedEvent(let value):
            return value
        case .typeCallTranscriptionStoppedEvent(let value):
            return value
        case .typeUnblockedUserEvent(let value):
            return value
        case .typeCallUpdatedEvent(let value):
            return value
        case .typeCallUserFeedbackSubmittedEvent(let value):
            return value
        case .typeCallUserMutedEvent(let value):
            return value
        case .typeConnectionErrorEvent(let value):
            return value
        case .typeConnectedEvent(let value):
            return value
        case .typeCustomVideoEvent(let value):
            return value
        case .typeHealthCheckEvent(let value):
            return value
        case .typeUserUpdatedEvent(let value):
            return value
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
