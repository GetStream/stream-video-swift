//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

#if compiler(>=6.0)
extension RTCSignalingState: @retroactive Encodable {}
extension RTCMediaStream: @retroactive Encodable {}
extension RTCRtpReceiver: @retroactive Encodable {}
extension RTCPeerConnectionState: @retroactive Encodable {}
extension RTCIceConnectionState: @retroactive Encodable {}
extension RTCIceGatheringState: @retroactive Encodable {}
extension RTCIceCandidate: @retroactive Encodable {}
extension RTCIceCandidateErrorEvent: @retroactive Encodable {}
extension RTCDataChannel: @retroactive Encodable {}
extension RTCSessionDescription: @retroactive Encodable {}
extension RTCConfiguration: @retroactive Encodable {}
extension RTCIceServer: @retroactive Encodable {}
extension RTCCryptoOptions: @retroactive Encodable {}
extension AVAudioSession.RouteChangeReason: @retroactive Encodable {}
#else
extension RTCSignalingState: Encodable {}
extension RTCMediaStream: Encodable {}
extension RTCRtpReceiver: Encodable {}
extension RTCPeerConnectionState: Encodable {}
extension RTCIceConnectionState: Encodable {}
extension RTCIceGatheringState: Encodable {}
extension RTCIceCandidate: Encodable {}
extension RTCIceCandidateErrorEvent: Encodable {}
extension RTCDataChannel: Encodable {}
extension RTCSessionDescription: Encodable {}
extension RTCConfiguration: Encodable {}
extension RTCIceServer: Encodable {}
extension RTCCryptoOptions: Encodable {}
extension AVAudioSession.RouteChangeReason: Encodable {}
#endif

extension RTCSignalingState {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension RTCMediaStream {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackId, forKey: .id)
        try container.encode(trackType.rawValue, forKey: .type)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
    }
}

extension RTCRtpReceiver {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(track?.trackId, forKey: .trackId)
        try container.encodeIfPresent(track?.kind, forKey: .trackType)
        try container.encode(parameters.rtcp.description, forKey: .rtcp)
    }

    private enum CodingKeys: String, CodingKey {
        case trackId
        case trackType
        case rtcp
    }
}

extension RTCPeerConnectionState {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension RTCIceConnectionState {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension RTCIceGatheringState {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension RTCIceCandidate {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sdpMid ?? "-", forKey: .sdpMid)
        try container.encode(sdpMLineIndex, forKey: .sdpMLineIndex)
        try container.encode(sdp, forKey: .sdp)
        try container.encode(serverUrl ?? "-", forKey: .serverUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case sdpMid
        case sdpMLineIndex
        case sdp
        case serverUrl
    }
}

extension RTCIceCandidateErrorEvent {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(address, forKey: .address)
        try container.encode(port, forKey: .port)
        try container.encode(url, forKey: .url)
        try container.encode(errorCode, forKey: .errorCode)
        try container.encode(errorText, forKey: .errorText)
    }

    private enum CodingKeys: String, CodingKey {
        case address
        case port
        case url
        case errorCode
        case errorText
    }
}

extension RTCDataChannel {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(isOrdered, forKey: .isOrdered)
        try container.encode(maxPacketLifeTime, forKey: .maxPacketLifeTime)
        try container.encode(maxRetransmits, forKey: .maxRetransmits)
        try container.encode(self.protocol, forKey: .protocol)
        try container.encode(isNegotiated, forKey: .isNegotiated)
        try container.encode(channelId, forKey: .channelId)
        try container.encode(readyState.description, forKey: .readyState)
        try container.encode(bufferedAmount, forKey: .bufferedAmount)
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case isOrdered
        case maxPacketLifeTime
        case maxRetransmits
        case `protocol`
        case isNegotiated
        case channelId
        case readyState
        case bufferedAmount
    }
}

extension RTCDataChannelState {
    public var description: String {
        switch self {
        case .connecting:
            return "connecting"
        case .open:
            return "open"
        case .closing:
            return "closing"
        case .closed:
            return "closed"
        @unknown default:
            return "unknown"
        }
    }
}

extension RTCSessionDescription {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.description, forKey: .type)
        try container.encode(sdp, forKey: .sdp)
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case sdp
    }
}

extension RTCIceServer {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(credential, forKey: .credential)
        try container.encode(urlStrings, forKey: .urlStrings)
        try container.encode(tlsCertPolicy.rawValue, forKey: .tlsCertPolicy)
        try container.encodeIfPresent(hostname, forKey: .hostname)
        try container.encode(tlsAlpnProtocols, forKey: .tlsAlpnProtocols)
        try container.encode(tlsEllipticCurves, forKey: .tlsEllipticCurves)
    }

    private enum CodingKeys: String, CodingKey {
        case urlStrings
        case username
        case credential
        case tlsCertPolicy
        case hostname
        case tlsAlpnProtocols
        case tlsEllipticCurves
    }
}

extension RTCCryptoOptions {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(srtpEnableGcmCryptoSuites, forKey: .srtpEnableGcmCryptoSuites)
        try container.encode(srtpEnableAes128Sha1_32CryptoCipher, forKey: .srtpEnableAes128Sha1_32CryptoCipher)
        try container.encode(srtpEnableEncryptedRtpHeaderExtensions, forKey: .srtpEnableEncryptedRtpHeaderExtensions)
        try container.encode(sframeRequireFrameEncryption, forKey: .sframeRequireFrameEncryption)
    }

    private enum CodingKeys: String, CodingKey {
        case srtpEnableGcmCryptoSuites
        case srtpEnableAes128Sha1_32CryptoCipher
        case srtpEnableEncryptedRtpHeaderExtensions
        case sframeRequireFrameEncryption
    }
}

extension RTCConfiguration {
    func toDictionary() -> [String: AnyEncodable] {
        var dict: [String: AnyEncodable] = [:]

        dict[CodingKeys.activeResetSrtpParams.rawValue] = AnyEncodable(activeResetSrtpParams)
        dict[CodingKeys.bundlePolicy.rawValue] = AnyEncodable(bundlePolicy.rawValue)
        dict[CodingKeys.enableIceGatheringOnAnyAddressPorts.rawValue] = AnyEncodable(enableIceGatheringOnAnyAddressPorts)
        dict[CodingKeys.continualGatheringPolicy.rawValue] = AnyEncodable(continualGatheringPolicy.rawValue)
        dict[CodingKeys.enableDscp.rawValue] = AnyEncodable(enableDscp)
        dict[CodingKeys.iceServers.rawValue] = AnyEncodable(iceServers)
        dict[CodingKeys.iceTransportPolicy.rawValue] = AnyEncodable(iceTransportPolicy.rawValue)
        dict[CodingKeys.rtcpMuxPolicy.rawValue] = AnyEncodable(rtcpMuxPolicy.rawValue)
        dict[CodingKeys.tcpCandidatePolicy.rawValue] = AnyEncodable(tcpCandidatePolicy.rawValue)
        dict[CodingKeys.candidateNetworkPolicy.rawValue] = AnyEncodable(candidateNetworkPolicy.rawValue)
        dict[CodingKeys.disableIPV6OnWiFi.rawValue] = AnyEncodable(disableIPV6OnWiFi)
        dict[CodingKeys.maxIPv6Networks.rawValue] = AnyEncodable(maxIPv6Networks)
        dict[CodingKeys.disableLinkLocalNetworks.rawValue] = AnyEncodable(disableLinkLocalNetworks)
        dict[CodingKeys.audioJitterBufferMaxPackets.rawValue] = AnyEncodable(audioJitterBufferMaxPackets)
        dict[CodingKeys.audioJitterBufferFastAccelerate.rawValue] = AnyEncodable(audioJitterBufferFastAccelerate)
        dict[CodingKeys.iceConnectionReceivingTimeout.rawValue] = AnyEncodable(iceConnectionReceivingTimeout)
        dict[CodingKeys.iceBackupCandidatePairPingInterval.rawValue] = AnyEncodable(iceBackupCandidatePairPingInterval)
        dict[CodingKeys.keyType.rawValue] = AnyEncodable(keyType.rawValue)
        dict[CodingKeys.iceCandidatePoolSize.rawValue] = AnyEncodable(iceCandidatePoolSize)
        dict[CodingKeys.shouldPruneTurnPorts.rawValue] = AnyEncodable(shouldPruneTurnPorts)
        dict[CodingKeys.shouldPresumeWritableWhenFullyRelayed.rawValue] = AnyEncodable(shouldPresumeWritableWhenFullyRelayed)
        dict[CodingKeys.shouldSurfaceIceCandidatesOnIceTransportTypeChanged.rawValue] =
            AnyEncodable(shouldSurfaceIceCandidatesOnIceTransportTypeChanged)
        dict[CodingKeys.iceCheckMinInterval.rawValue] = iceCheckMinInterval.map { AnyEncodable($0.doubleValue) }
        dict[CodingKeys.sdpSemantics.rawValue] = AnyEncodable(sdpSemantics.rawValue)
        dict[CodingKeys.cryptoOptions.rawValue] = cryptoOptions.map { AnyEncodable($0) }
        dict[CodingKeys.turnLoggingId.rawValue] = turnLoggingId.map { AnyEncodable($0) }
        dict[CodingKeys.rtcpAudioReportIntervalMs.rawValue] = AnyEncodable(rtcpAudioReportIntervalMs)
        dict[CodingKeys.rtcpVideoReportIntervalMs.rawValue] = AnyEncodable(rtcpVideoReportIntervalMs)
        dict[CodingKeys.enableImplicitRollback.rawValue] = AnyEncodable(enableImplicitRollback)
        dict[CodingKeys.offerExtmapAllowMixed.rawValue] = AnyEncodable(offerExtmapAllowMixed)
        dict[CodingKeys.iceCheckIntervalStrongConnectivity.rawValue] = iceCheckIntervalStrongConnectivity
            .map { AnyEncodable($0.doubleValue) }
        dict[CodingKeys.iceCheckIntervalWeakConnectivity.rawValue] = iceCheckIntervalWeakConnectivity
            .map { AnyEncodable($0.doubleValue) }
        dict[CodingKeys.iceUnwritableTimeout.rawValue] = iceUnwritableTimeout.map { AnyEncodable($0.doubleValue) }
        dict[CodingKeys.iceUnwritableMinChecks.rawValue] = iceUnwritableMinChecks.map { AnyEncodable($0.intValue) }
        dict[CodingKeys.iceInactiveTimeout.rawValue] = iceInactiveTimeout.map { AnyEncodable($0.doubleValue) }

        return dict
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(activeResetSrtpParams, forKey: .activeResetSrtpParams)
        try container.encode(bundlePolicy.rawValue, forKey: .bundlePolicy)
        try container.encode(enableIceGatheringOnAnyAddressPorts, forKey: .enableIceGatheringOnAnyAddressPorts)
        try container.encode(continualGatheringPolicy.rawValue, forKey: .continualGatheringPolicy)
        try container.encode(enableDscp, forKey: .enableDscp)
        try container.encode(iceServers, forKey: .iceServers)
        try container.encode(iceTransportPolicy.rawValue, forKey: .iceTransportPolicy)
        try container.encode(rtcpMuxPolicy.rawValue, forKey: .rtcpMuxPolicy)
        try container.encode(tcpCandidatePolicy.rawValue, forKey: .tcpCandidatePolicy)
        try container.encode(candidateNetworkPolicy.rawValue, forKey: .candidateNetworkPolicy)
        try container.encode(disableIPV6OnWiFi, forKey: .disableIPV6OnWiFi)
        try container.encode(maxIPv6Networks, forKey: .maxIPv6Networks)
        try container.encode(disableLinkLocalNetworks, forKey: .disableLinkLocalNetworks)
        try container.encode(audioJitterBufferMaxPackets, forKey: .audioJitterBufferMaxPackets)
        try container.encode(audioJitterBufferFastAccelerate, forKey: .audioJitterBufferFastAccelerate)
        try container.encode(iceConnectionReceivingTimeout, forKey: .iceConnectionReceivingTimeout)
        try container.encode(iceBackupCandidatePairPingInterval, forKey: .iceBackupCandidatePairPingInterval)
        try container.encode(keyType.rawValue, forKey: .keyType)
        try container.encode(iceCandidatePoolSize, forKey: .iceCandidatePoolSize)
        try container.encode(shouldPruneTurnPorts, forKey: .shouldPruneTurnPorts)
        try container.encode(shouldPresumeWritableWhenFullyRelayed, forKey: .shouldPresumeWritableWhenFullyRelayed)
        try container.encode(
            shouldSurfaceIceCandidatesOnIceTransportTypeChanged,
            forKey: .shouldSurfaceIceCandidatesOnIceTransportTypeChanged
        )
        try container.encodeIfPresent(iceCheckMinInterval?.doubleValue, forKey: .iceCheckMinInterval)
        try container.encode(sdpSemantics.rawValue, forKey: .sdpSemantics)
        try container.encodeIfPresent(cryptoOptions, forKey: .cryptoOptions)
        try container.encodeIfPresent(turnLoggingId, forKey: .turnLoggingId)
        try container.encode(rtcpAudioReportIntervalMs, forKey: .rtcpAudioReportIntervalMs)
        try container.encode(rtcpVideoReportIntervalMs, forKey: .rtcpVideoReportIntervalMs)
        try container.encode(enableImplicitRollback, forKey: .enableImplicitRollback)
        try container.encode(offerExtmapAllowMixed, forKey: .offerExtmapAllowMixed)
        try container.encodeIfPresent(iceCheckIntervalStrongConnectivity?.doubleValue, forKey: .iceCheckIntervalStrongConnectivity)
        try container.encodeIfPresent(iceCheckIntervalWeakConnectivity?.doubleValue, forKey: .iceCheckIntervalWeakConnectivity)
        try container.encodeIfPresent(iceUnwritableTimeout?.doubleValue, forKey: .iceUnwritableTimeout)
        try container.encodeIfPresent(iceUnwritableMinChecks?.intValue, forKey: .iceUnwritableMinChecks)
        try container.encodeIfPresent(iceInactiveTimeout?.doubleValue, forKey: .iceInactiveTimeout)
    }

    private enum CodingKeys: String, CodingKey {
        case enableDscp
        case iceServers
        case iceTransportPolicy
        case bundlePolicy
        case rtcpMuxPolicy
        case tcpCandidatePolicy
        case candidateNetworkPolicy
        case continualGatheringPolicy
        case disableIPV6OnWiFi
        case maxIPv6Networks
        case disableLinkLocalNetworks
        case audioJitterBufferMaxPackets
        case audioJitterBufferFastAccelerate
        case iceConnectionReceivingTimeout
        case iceBackupCandidatePairPingInterval
        case keyType
        case iceCandidatePoolSize
        case shouldPruneTurnPorts
        case shouldPresumeWritableWhenFullyRelayed
        case shouldSurfaceIceCandidatesOnIceTransportTypeChanged
        case iceCheckMinInterval
        case sdpSemantics
        case activeResetSrtpParams
        case cryptoOptions
        case turnLoggingId
        case rtcpAudioReportIntervalMs
        case rtcpVideoReportIntervalMs
        case enableImplicitRollback
        case offerExtmapAllowMixed
        case iceCheckIntervalStrongConnectivity
        case iceCheckIntervalWeakConnectivity
        case iceUnwritableTimeout
        case iceUnwritableMinChecks
        case iceInactiveTimeout
        case enableIceGatheringOnAnyAddressPorts
    }
}

extension RTCBundlePolicy {
    public var description: String {
        switch self {
        case .maxCompat:
            return "max-compat"
        case .maxBundle:
            return "max-bundle"
        case .balanced:
            return "balanced"
        @unknown default:
            return "default"
        }
    }
}

extension RTCContinualGatheringPolicy {
    public var description: String {
        switch self {
        case .gatherContinually:
            return "gather-continually"
        case .gatherOnce:
            return "gather-once"
        @unknown default:
            return "unknown"
        }
    }
}
