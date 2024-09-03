//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserSessionStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var browser: String? = nil
    public var browserVersion: String? = nil
    public var currentIp: String? = nil
    public var currentSfu: String? = nil
    public var deviceModel: String? = nil
    public var deviceVersion: String? = nil
    public var distanceToSfuKilometers: Double? = nil
    public var freezeDurationSeconds: Int
    public var geolocation: GeolocationResult? = nil
    public var jitter: Stats? = nil
    public var latency: Stats? = nil
    public var maxFirPerSecond: Double? = nil
    public var maxFreezeFraction: Double
    public var maxFreezesDurationSeconds: Int
    public var maxFreezesPerSecond: Double? = nil
    public var maxNackPerSecond: Double? = nil
    public var maxPliPerSecond: Double? = nil
    public var maxPublishingVideoQuality: VideoQuality? = nil
    public var maxReceivingVideoQuality: VideoQuality? = nil
    public var os: String? = nil
    public var osVersion: String? = nil
    public var packetLossFraction: Double
    public var pubSubHints: MediaPubSubHint? = nil
    public var publishedTracks: [PublishedTrackInfo]? = nil
    public var publisherAudioMos: MOSStats? = nil
    public var publisherJitter: Stats? = nil
    public var publisherLatency: Stats? = nil
    public var publisherNoiseCancellationSeconds: Double? = nil
    public var publisherPacketLossFraction: Double
    public var publisherQualityLimitationFraction: Double? = nil
    public var publisherVideoQualityLimitationDurationSeconds: [String: Double]? = nil
    public var publishingAudioCodec: String? = nil
    public var publishingDurationSeconds: Int
    public var publishingVideoCodec: String? = nil
    public var qualityScore: Double
    public var receivingAudioCodec: String? = nil
    public var receivingDurationSeconds: Int
    public var receivingVideoCodec: String? = nil
    public var sdk: String? = nil
    public var sdkVersion: String? = nil
    public var sessionId: String
    public var subscriberAudioMos: MOSStats? = nil
    public var subscriberJitter: Stats? = nil
    public var subscriberLatency: Stats? = nil
    public var subscriberVideoQualityThrottledDurationSeconds: Double? = nil
    public var subsessions: [Subsession?]? = nil
    public var timeline: CallTimeline? = nil
    public var totalPixelsIn: Int
    public var totalPixelsOut: Int
    public var truncated: Bool? = nil
    public var webrtcVersion: String? = nil

    public init(
        browser: String? = nil,
        browserVersion: String? = nil,
        currentIp: String? = nil,
        currentSfu: String? = nil,
        deviceModel: String? = nil,
        deviceVersion: String? = nil,
        distanceToSfuKilometers: Double? = nil,
        freezeDurationSeconds: Int,
        geolocation: GeolocationResult? = nil,
        jitter: Stats? = nil,
        latency: Stats? = nil,
        maxFirPerSecond: Double? = nil,
        maxFreezeFraction: Double,
        maxFreezesDurationSeconds: Int,
        maxFreezesPerSecond: Double? = nil,
        maxNackPerSecond: Double? = nil,
        maxPliPerSecond: Double? = nil,
        maxPublishingVideoQuality: VideoQuality? = nil,
        maxReceivingVideoQuality: VideoQuality? = nil,
        os: String? = nil,
        osVersion: String? = nil,
        packetLossFraction: Double,
        pubSubHints: MediaPubSubHint? = nil,
        publishedTracks: [PublishedTrackInfo]? = nil,
        publisherAudioMos: MOSStats? = nil,
        publisherJitter: Stats? = nil,
        publisherLatency: Stats? = nil,
        publisherNoiseCancellationSeconds: Double? = nil,
        publisherPacketLossFraction: Double,
        publisherQualityLimitationFraction: Double? = nil,
        publisherVideoQualityLimitationDurationSeconds: [String: Double]? = nil,
        publishingAudioCodec: String? = nil,
        publishingDurationSeconds: Int,
        publishingVideoCodec: String? = nil,
        qualityScore: Double,
        receivingAudioCodec: String? = nil,
        receivingDurationSeconds: Int,
        receivingVideoCodec: String? = nil,
        sdk: String? = nil,
        sdkVersion: String? = nil,
        sessionId: String,
        subscriberAudioMos: MOSStats? = nil,
        subscriberJitter: Stats? = nil,
        subscriberLatency: Stats? = nil,
        subscriberVideoQualityThrottledDurationSeconds: Double? = nil,
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
