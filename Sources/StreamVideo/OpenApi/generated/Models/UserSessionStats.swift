//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserSessionStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var averageConnectionTime: Float?
    public var browser: String?
    public var browserVersion: String?
    public var currentIp: String?
    public var currentSfu: String?
    public var deviceModel: String?
    public var deviceVersion: String?
    public var distanceToSfuKilometers: Float?
    public var freezeDurationSeconds: Int
    public var geolocation: GeolocationResult?
    public var group: String
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
    public var minEventTs: Int
    public var os: String?
    public var osVersion: String?
    public var packetLossFraction: Float
    public var pubSubHints: MediaPubSubHint?
    public var publishedTracks: [PublishedTrackInfo]?
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
    public var subscriberJitter: Stats?
    public var subscriberLatency: Stats?
    public var subscriberVideoQualityThrottledDurationSeconds: Float?
    public var subsessions: [Subsession]?
    public var timeline: CallTimeline?
    public var totalPixelsIn: Int
    public var totalPixelsOut: Int
    public var truncated: Bool?
    public var webrtcVersion: String?

    public init(
        averageConnectionTime: Float? = nil,
        browser: String? = nil,
        browserVersion: String? = nil,
        currentIp: String? = nil,
        currentSfu: String? = nil,
        deviceModel: String? = nil,
        deviceVersion: String? = nil,
        distanceToSfuKilometers: Float? = nil,
        freezeDurationSeconds: Int,
        geolocation: GeolocationResult? = nil,
        group: String,
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
        minEventTs: Int,
        os: String? = nil,
        osVersion: String? = nil,
        packetLossFraction: Float,
        pubSubHints: MediaPubSubHint? = nil,
        publishedTracks: [PublishedTrackInfo]? = nil,
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
        subscriberJitter: Stats? = nil,
        subscriberLatency: Stats? = nil,
        subscriberVideoQualityThrottledDurationSeconds: Float? = nil,
        subsessions: [Subsession]? = nil,
        timeline: CallTimeline? = nil,
        totalPixelsIn: Int,
        totalPixelsOut: Int,
        truncated: Bool? = nil,
        webrtcVersion: String? = nil
    ) {
        self.averageConnectionTime = averageConnectionTime
        self.browser = browser
        self.browserVersion = browserVersion
        self.currentIp = currentIp
        self.currentSfu = currentSfu
        self.deviceModel = deviceModel
        self.deviceVersion = deviceVersion
        self.distanceToSfuKilometers = distanceToSfuKilometers
        self.freezeDurationSeconds = freezeDurationSeconds
        self.geolocation = geolocation
        self.group = group
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
        self.minEventTs = minEventTs
        self.os = os
        self.osVersion = osVersion
        self.packetLossFraction = packetLossFraction
        self.pubSubHints = pubSubHints
        self.publishedTracks = publishedTracks
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
        case averageConnectionTime = "average_connection_time"
        case browser
        case browserVersion = "browser_version"
        case currentIp = "current_ip"
        case currentSfu = "current_sfu"
        case deviceModel = "device_model"
        case deviceVersion = "device_version"
        case distanceToSfuKilometers = "distance_to_sfu_kilometers"
        case freezeDurationSeconds = "freeze_duration_seconds"
        case geolocation
        case group
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
        case minEventTs = "min_event_ts"
        case os
        case osVersion = "os_version"
        case packetLossFraction = "packet_loss_fraction"
        case pubSubHints = "pub_sub_hints"
        case publishedTracks = "published_tracks"
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
    
    public static func == (lhs: UserSessionStats, rhs: UserSessionStats) -> Bool {
        lhs.averageConnectionTime == rhs.averageConnectionTime &&
            lhs.browser == rhs.browser &&
            lhs.browserVersion == rhs.browserVersion &&
            lhs.currentIp == rhs.currentIp &&
            lhs.currentSfu == rhs.currentSfu &&
            lhs.deviceModel == rhs.deviceModel &&
            lhs.deviceVersion == rhs.deviceVersion &&
            lhs.distanceToSfuKilometers == rhs.distanceToSfuKilometers &&
            lhs.freezeDurationSeconds == rhs.freezeDurationSeconds &&
            lhs.geolocation == rhs.geolocation &&
            lhs.group == rhs.group &&
            lhs.jitter == rhs.jitter &&
            lhs.latency == rhs.latency &&
            lhs.maxFirPerSecond == rhs.maxFirPerSecond &&
            lhs.maxFreezeFraction == rhs.maxFreezeFraction &&
            lhs.maxFreezesDurationSeconds == rhs.maxFreezesDurationSeconds &&
            lhs.maxFreezesPerSecond == rhs.maxFreezesPerSecond &&
            lhs.maxNackPerSecond == rhs.maxNackPerSecond &&
            lhs.maxPliPerSecond == rhs.maxPliPerSecond &&
            lhs.maxPublishingVideoQuality == rhs.maxPublishingVideoQuality &&
            lhs.maxReceivingVideoQuality == rhs.maxReceivingVideoQuality &&
            lhs.minEventTs == rhs.minEventTs &&
            lhs.os == rhs.os &&
            lhs.osVersion == rhs.osVersion &&
            lhs.packetLossFraction == rhs.packetLossFraction &&
            lhs.pubSubHints == rhs.pubSubHints &&
            lhs.publishedTracks == rhs.publishedTracks &&
            lhs.publisherJitter == rhs.publisherJitter &&
            lhs.publisherLatency == rhs.publisherLatency &&
            lhs.publisherNoiseCancellationSeconds == rhs.publisherNoiseCancellationSeconds &&
            lhs.publisherPacketLossFraction == rhs.publisherPacketLossFraction &&
            lhs.publisherQualityLimitationFraction == rhs.publisherQualityLimitationFraction &&
            lhs.publisherVideoQualityLimitationDurationSeconds == rhs.publisherVideoQualityLimitationDurationSeconds &&
            lhs.publishingAudioCodec == rhs.publishingAudioCodec &&
            lhs.publishingDurationSeconds == rhs.publishingDurationSeconds &&
            lhs.publishingVideoCodec == rhs.publishingVideoCodec &&
            lhs.qualityScore == rhs.qualityScore &&
            lhs.receivingAudioCodec == rhs.receivingAudioCodec &&
            lhs.receivingDurationSeconds == rhs.receivingDurationSeconds &&
            lhs.receivingVideoCodec == rhs.receivingVideoCodec &&
            lhs.sdk == rhs.sdk &&
            lhs.sdkVersion == rhs.sdkVersion &&
            lhs.sessionId == rhs.sessionId &&
            lhs.subscriberJitter == rhs.subscriberJitter &&
            lhs.subscriberLatency == rhs.subscriberLatency &&
            lhs.subscriberVideoQualityThrottledDurationSeconds == rhs.subscriberVideoQualityThrottledDurationSeconds &&
            lhs.subsessions == rhs.subsessions &&
            lhs.timeline == rhs.timeline &&
            lhs.totalPixelsIn == rhs.totalPixelsIn &&
            lhs.totalPixelsOut == rhs.totalPixelsOut &&
            lhs.truncated == rhs.truncated &&
            lhs.webrtcVersion == rhs.webrtcVersion
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(averageConnectionTime)
        hasher.combine(browser)
        hasher.combine(browserVersion)
        hasher.combine(currentIp)
        hasher.combine(currentSfu)
        hasher.combine(deviceModel)
        hasher.combine(deviceVersion)
        hasher.combine(distanceToSfuKilometers)
        hasher.combine(freezeDurationSeconds)
        hasher.combine(geolocation)
        hasher.combine(group)
        hasher.combine(jitter)
        hasher.combine(latency)
        hasher.combine(maxFirPerSecond)
        hasher.combine(maxFreezeFraction)
        hasher.combine(maxFreezesDurationSeconds)
        hasher.combine(maxFreezesPerSecond)
        hasher.combine(maxNackPerSecond)
        hasher.combine(maxPliPerSecond)
        hasher.combine(maxPublishingVideoQuality)
        hasher.combine(maxReceivingVideoQuality)
        hasher.combine(minEventTs)
        hasher.combine(os)
        hasher.combine(osVersion)
        hasher.combine(packetLossFraction)
        hasher.combine(pubSubHints)
        hasher.combine(publishedTracks)
        hasher.combine(publisherJitter)
        hasher.combine(publisherLatency)
        hasher.combine(publisherNoiseCancellationSeconds)
        hasher.combine(publisherPacketLossFraction)
        hasher.combine(publisherQualityLimitationFraction)
        hasher.combine(publisherVideoQualityLimitationDurationSeconds)
        hasher.combine(publishingAudioCodec)
        hasher.combine(publishingDurationSeconds)
        hasher.combine(publishingVideoCodec)
        hasher.combine(qualityScore)
        hasher.combine(receivingAudioCodec)
        hasher.combine(receivingDurationSeconds)
        hasher.combine(receivingVideoCodec)
        hasher.combine(sdk)
        hasher.combine(sdkVersion)
        hasher.combine(sessionId)
        hasher.combine(subscriberJitter)
        hasher.combine(subscriberLatency)
        hasher.combine(subscriberVideoQualityThrottledDurationSeconds)
        hasher.combine(subsessions)
        hasher.combine(timeline)
        hasher.combine(totalPixelsIn)
        hasher.combine(totalPixelsOut)
        hasher.combine(truncated)
        hasher.combine(webrtcVersion)
    }
}
