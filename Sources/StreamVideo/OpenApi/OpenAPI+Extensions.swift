//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// MARK: - JSON coders

// Default coders of the generated DefaultAPI.

extension JSONDecoder {
    static var `default`: JSONDecoder { .streamCore }
}

extension JSONEncoder {
    static var `default`: JSONEncoder { .streamCore }
}

// MARK: - Typealiases

// The generator prefixes nested enums with the model name. These aliases keep
// the unprefixed names.

extension AudioSettings {
    /// Same as ``AudioSettingsDefaultDevice``.
    public typealias DefaultDevice = AudioSettingsDefaultDevice
}

extension AudioSettingsRequest {
    /// Same as ``AudioSettingsRequestDefaultDevice``.
    public typealias DefaultDevice = AudioSettingsRequestDefaultDevice
}

extension LayoutSettings {
    /// Same as ``LayoutSettingsName``.
    public typealias Name = LayoutSettingsName
}

extension NoiseCancellationSettingsRequest {
    /// Same as ``NoiseCancellationSettingsRequestMode``.
    public typealias Mode = NoiseCancellationSettingsRequestMode
}

extension RecordSettingsRequest {
    /// Same as ``RecordSettingsRequestMode``.
    public typealias Mode = RecordSettingsRequestMode

    /// Same as ``RecordSettingsRequestQuality``.
    public typealias Quality = RecordSettingsRequestQuality
}

extension RTMPBroadcastRequest {
    /// Same as ``RTMPBroadcastRequestQuality``.
    public typealias Quality = RTMPBroadcastRequestQuality
}

extension RTMPSettingsRequest {
    /// Same as ``RTMPSettingsRequestQuality``.
    public typealias Quality = RTMPSettingsRequestQuality
}

extension TranscriptionSettings {
    /// Same as ``TranscriptionSettingsClosedCaptionMode``.
    public typealias ClosedCaptionMode = TranscriptionSettingsClosedCaptionMode

    /// Same as ``TranscriptionSettingsLanguage``.
    public typealias Language = TranscriptionSettingsLanguage

    /// Same as ``TranscriptionSettingsMode``.
    public typealias Mode = TranscriptionSettingsMode
}

extension TranscriptionSettingsRequest {
    /// Same as ``TranscriptionSettingsRequestClosedCaptionMode``.
    public typealias ClosedCaptionMode = TranscriptionSettingsRequestClosedCaptionMode

    /// Same as ``TranscriptionSettingsRequestLanguage``.
    public typealias Language = TranscriptionSettingsRequestLanguage

    /// Same as ``TranscriptionSettingsRequestMode``.
    public typealias Mode = TranscriptionSettingsRequestMode
}

extension VideoSettings {
    /// Same as ``VideoSettingsCameraFacing``.
    public typealias CameraFacing = VideoSettingsCameraFacing
}

extension VideoSettingsRequest {
    /// Same as ``VideoSettingsRequestCameraFacing``.
    public typealias CameraFacing = VideoSettingsRequestCameraFacing
}

// MARK: - Deprecated

// Members the video API no longer has. They keep the public interface stable
// until the next major version removes them.

extension GoLiveRequest {
    /// Removed from the video API. Always `nil`; setting it has no effect.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public var startRtmpBroadcasts: Bool? {
        get { nil }
        set {}
    }

    /// Creates a request. The video API ignores `startRtmpBroadcasts`.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public convenience init(
        recordingStorageName: String? = nil,
        startClosedCaption: Bool? = nil,
        startHls: Bool? = nil,
        startRecording: Bool? = nil,
        startRtmpBroadcasts: Bool? = nil,
        startTranscription: Bool? = nil,
        transcriptionStorageName: String? = nil
    ) {
        self.init(
            recordingStorageName: recordingStorageName,
            startClosedCaption: startClosedCaption,
            startHls: startHls,
            startRecording: startRecording,
            startTranscription: startTranscription,
            transcriptionStorageName: transcriptionStorageName
        )
    }
}

extension OwnUserResponse {
    /// Removed from the video API. Always `nil`; setting it has no effect.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public var pushNotifications: PushNotificationSettingsResponse? {
        get { nil }
        set {}
    }

    /// Removed from the video API. Always `nil`; setting it has no effect.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public var revokeTokensIssuedBefore: Date? {
        get { nil }
        set {}
    }

    /// Creates a response. The video API ignores `pushNotifications` and
    /// `revokeTokensIssuedBefore`.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public convenience init(
        blockedUserIds: [String]? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        devices: [Device],
        id: String,
        image: String? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        pushNotifications: PushNotificationSettingsResponse? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String],
        updatedAt: Date
    ) {
        self.init(
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            devices: devices,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            role: role,
            teams: teams,
            updatedAt: updatedAt
        )
    }
}

extension UserEventPayload {
    /// Removed from the video API. Always `nil`; setting it has no effect.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public var revokeTokensIssuedBefore: Date? {
        get { nil }
        set {}
    }

    /// Creates a payload. The video API ignores `revokeTokensIssuedBefore`.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public convenience init(
        blockedUserIds: [String],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        invisible: Bool? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String],
        updatedAt: Date
    ) {
        self.init(
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            invisible: invisible,
            language: language,
            lastActive: lastActive,
            name: name,
            role: role,
            teams: teams,
            updatedAt: updatedAt
        )
    }
}

extension UserResponse {
    /// Removed from the video API. Always `nil`; setting it has no effect.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public var revokeTokensIssuedBefore: Date? {
        get { nil }
        set {}
    }

    /// Creates a response. The video API ignores `revokeTokensIssuedBefore`.
    @available(*, deprecated, message: "No longer part of the video API. It will be removed in the next major version.")
    public convenience init(
        blockedUserIds: [String],
        createdAt: Date,
        custom: [String: RawJSON],
        deactivatedAt: Date? = nil,
        deletedAt: Date? = nil,
        id: String,
        image: String? = nil,
        language: String,
        lastActive: Date? = nil,
        name: String? = nil,
        revokeTokensIssuedBefore: Date? = nil,
        role: String,
        teams: [String],
        updatedAt: Date
    ) {
        self.init(
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            role: role,
            teams: teams,
            updatedAt: updatedAt
        )
    }
}
