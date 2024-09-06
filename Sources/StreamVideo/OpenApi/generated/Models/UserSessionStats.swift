//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserSessionStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var browser: String?
    public var browserVersion: String?
    public var currentIp: String?
    public var currentSfu: String?
    public var deviceModel: String?
    public var deviceVersion: String?
    public var distanceToSfuKilometers: Float?
    public var freezeDurationSeconds: Int
    public var geolocation: GeolocationResult?
    public var jitter: Stats?
    public var latency: Stats?
    public var maxFirPerSecond: Float?
    public var maxFreezeFraction: Float
    public var maxFreezesDurationSeconds: Int
    public var maxFreezesPerSecond: Float?
    public var maxNackPerSecond: Float?
    public var maxPliPerSecond: Float?
    public var maxPublishingVideoQuality: VideoQuality?
    public var maxReceivingVideoQuality: VideoQuality?
    public var os: String?
    public var osVersion: String?
    public var packetLossFraction: Float
    public var pubSubHints: MediaPubSubHint?
    public var publishedTracks: [PublishedTrackInfo]?
    public var publisherAudioMos: MOSStats?
    public var publisherJitter: Stats?
    public var publisherLatency: Stats?
    public var publisherNoiseCancellationSeconds: Float?
    public var publisherPacketLossFraction: Float
    public var publisherQualityLimitationFraction: Float?
    public var publisherVideoQualityLimitationDurationSeconds: [String: Float]?
    public var publishingAudioCodec: String?
    public var publishingDurationSeconds: Int
    public var publishingVideoCodec: String?
    public var qualityScore: Float
    public var receivingAudioCodec: String?
    public var receivingDurationSeconds: Int
    public var receivingVideoCodec: String?
    public var sdk: String?
    public var sdkVersion: String?
    public var sessionId: String
    public var subscriberAudioMos: MOSStats?
    public var subscriberJitter: Stats?
    public var subscriberLatency: Stats?
    public var subscriberVideoQualityThrottledDurationSeconds: Float?
    public var subsessions: [Subsession?]?
    public var timeline: CallTimeline?
    public var totalPixelsIn: Int
    public var totalPixelsOut: Int
    public var truncated: Bool?
    public var webrtcVersion: String?

    public init(
        browser: String? = nil,
        browserVersion: String? = nil,
        currentIp: String? = nil,
        currentSfu: String? = nil,
        deviceModel: String? = nil,
        deviceVersion: String? = nil,
        distanceToSfuKilometers: Float? = nil,
        freezeDurationSeconds: Int,
        geolocation: GeolocationResult? = nil,
        jitter: Stats? = nil,
        latency: Stats? = nil,
        maxFirPerSecond: Float? = nil,
        maxFreezeFraction: Float,
        maxFreezesDurationSeconds: Int,
        maxFreezesPerSecond: Float? = nil,
        maxNackPerSecond: Float? = nil,
        maxPliPerSecond: Float? = nil,
        maxPublishingVideoQuality: VideoQuality? = nil,
        maxReceivingVideoQuality: VideoQuality? = nil,
        os: String? = nil,
        osVersion: String? = nil,
        packetLossFraction: Float,
        pubSubHints: MediaPubSubHint? = nil,
        publishedTracks: [PublishedTrackInfo]? = nil,
        publisherAudioMos: MOSStats? = nil,
        publisherJitter: Stats? = nil,
        publisherLatency: Stats? = nil,
        publisherNoiseCancellationSeconds: Float? = nil,
        publisherPacketLossFraction: Float,
        publisherQualityLimitationFraction: Float? = nil,
        publisherVideoQualityLimitationDurationSeconds: [String: Float]? = nil,
        publishingAudioCodec: String? = nil,
        publishingDurationSeconds: Int,
        publishingVideoCodec: String? = nil,
        qualityScore: Float,
        receivingAudioCodec: String? = nil,
        receivingDurationSeconds: Int,
        receivingVideoCodec: String? = nil,
        sdk: String? = nil,
        sdkVersion: String? = nil,
        sessionId: String,
        subscriberAudioMos: MOSStats? = nil,
        subscriberJitter: Stats? = nil,
        subscriberLatency: Stats? = nil,
        subscriberVideoQualityThrottledDurationSeconds: Float? = nil,
        subsessions: [Subsession?]? = nil,
        timeline: CallTimeline? = nil,
        totalPixelsIn: Int,
        totalPixelsOut: Int,
        truncated: Bool? = nil,
        webrtcVersion: String? = nil
    ) {
        self.browser = browser
        self.browserVersion = browserVersion
        self.currentIp = currentIp
        self.currentSfu = currentSfu
        self.deviceModel = deviceModel
        self.deviceVersion = deviceVersion
        self.distanceToSfuKilometers = distanceToSfuKilometers
        self.freezeDurationSeconds = freezeDurationSeconds
        self.geolocation = geolocation
        self.jitter = jitter
        self.latency = latency
        self.maxFirPerSecond = maxFirPerSecond
        self.maxFreezeFraction = maxFreezeFraction
        self.maxFreezesDurationSeconds = maxFreezesDurationSeconds
        self.maxFreezesPerSecond = maxFreezesPerSecond
        self.maxNackPerSecond = maxNackPerSecond
        self.maxPliPerSecond = maxPliPerSecond
        self.maxPublishingVideoQuality = maxPublishingVideoQuality
        self.maxReceivingVideoQuality = maxReceivingVideoQuality
        self.os = os
        self.osVersion = osVersion
        self.packetLossFraction = packetLossFraction
        self.pubSubHints = pubSubHints
        self.publishedTracks = publishedTracks
        self.publisherAudioMos = publisherAudioMos
        self.publisherJitter = publisherJitter
        self.publisherLatency = publisherLatency
        self.publisherNoiseCancellationSeconds = publisherNoiseCancellationSeconds
        self.publisherPacketLossFraction = publisherPacketLossFraction
        self.publisherQualityLimitationFraction = publisherQualityLimitationFraction
        self.publisherVideoQualityLimitationDurationSeconds = publisherVideoQualityLimitationDurationSeconds
        self.publishingAudioCodec = publishingAudioCodec
        self.publishingDurationSeconds = publishingDurationSeconds
        self.publishingVideoCodec = publishingVideoCodec
        self.qualityScore = qualityScore
        self.receivingAudioCodec = receivingAudioCodec
        self.receivingDurationSeconds = receivingDurationSeconds
        self.receivingVideoCodec = receivingVideoCodec
        self.sdk = sdk
        self.sdkVersion = sdkVersion
        self.sessionId = sessionId
        self.subscriberAudioMos = subscriberAudioMos
        self.subscriberJitter = subscriberJitter
        self.subscriberLatency = subscriberLatency
        self.subscriberVideoQualityThrottledDurationSeconds = subscriberVideoQualityThrottledDurationSeconds
        self.subsessions = subsessions
        self.timeline = timeline
        self.totalPixelsIn = totalPixelsIn
        self.totalPixelsOut = totalPixelsOut
        self.truncated = truncated
        self.webrtcVersion = webrtcVersion
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case browser
        case browserVersion = "browser_version"
        case currentIp = "current_ip"
        case currentSfu = "current_sfu"
        case deviceModel = "device_model"
        case deviceVersion = "device_version"
        case distanceToSfuKilometers = "distance_to_sfu_kilometers"
        case freezeDurationSeconds = "freeze_duration_seconds"
        case geolocation
        case jitter
        case latency
        case maxFirPerSecond = "max_fir_per_second"
        case maxFreezeFraction = "max_freeze_fraction"
        case maxFreezesDurationSeconds = "max_freezes_duration_seconds"
        case maxFreezesPerSecond = "max_freezes_per_second"
        case maxNackPerSecond = "max_nack_per_second"
        case maxPliPerSecond = "max_pli_per_second"
        case maxPublishingVideoQuality = "max_publishing_video_quality"
        case maxReceivingVideoQuality = "max_receiving_video_quality"
        case os
        case osVersion = "os_version"
        case packetLossFraction = "packet_loss_fraction"
        case pubSubHints = "pub_sub_hints"
        case publishedTracks = "published_tracks"
        case publisherAudioMos = "publisher_audio_mos"
        case publisherJitter = "publisher_jitter"
        case publisherLatency = "publisher_latency"
        case publisherNoiseCancellationSeconds = "publisher_noise_cancellation_seconds"
        case publisherPacketLossFraction = "publisher_packet_loss_fraction"
        case publisherQualityLimitationFraction = "publisher_quality_limitation_fraction"
        case publisherVideoQualityLimitationDurationSeconds = "publisher_video_quality_limitation_duration_seconds"
        case publishingAudioCodec = "publishing_audio_codec"
        case publishingDurationSeconds = "publishing_duration_seconds"
        case publishingVideoCodec = "publishing_video_codec"
        case qualityScore = "quality_score"
        case receivingAudioCodec = "receiving_audio_codec"
        case receivingDurationSeconds = "receiving_duration_seconds"
        case receivingVideoCodec = "receiving_video_codec"
        case sdk
        case sdkVersion = "sdk_version"
        case sessionId = "session_id"
        case subscriberAudioMos = "subscriber_audio_mos"
        case subscriberJitter = "subscriber_jitter"
        case subscriberLatency = "subscriber_latency"
        case subscriberVideoQualityThrottledDurationSeconds = "subscriber_video_quality_throttled_duration_seconds"
        case subsessions
        case timeline
        case totalPixelsIn = "total_pixels_in"
        case totalPixelsOut = "total_pixels_out"
        case truncated
        case webrtcVersion = "webrtc_version"
    }
}
