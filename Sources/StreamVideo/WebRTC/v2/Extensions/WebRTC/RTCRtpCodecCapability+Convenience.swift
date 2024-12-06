//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCRtpCodecCapability {
    var fmtp: String {
        parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
    }
}

extension Sequence where Element == RTCRtpCodecCapability {

    func baseline(for videoCodec: VideoCodec) -> RTCRtpCodecCapability? {
        filter { $0.name.lowercased() == videoCodec.rawValue }
            .sorted(by: videoCodec.baselineComparator)
            .first
    }

    func baseline(for audioCodec: AudioCodec) -> RTCRtpCodecCapability? {
        filter { $0.name.lowercased() == audioCodec.rawValue }
            .sorted(by: audioCodec.baselineComparator)
            .first
    }
}

extension VideoCodec {
    fileprivate var baselineComparator: (RTCRtpCodecCapability, RTCRtpCodecCapability) -> Bool {
        switch self {
        case .h264:
            return h264Comparator
        case .vp8:
            return noOpComparator
        case .vp9:
            return vp9Comparator
        case .av1:
            return noOpComparator
        case .none:
            return noOpComparator
        }
    }
}

extension AudioCodec {
    fileprivate var baselineComparator: (RTCRtpCodecCapability, RTCRtpCodecCapability) -> Bool {
        switch self {
        case .none:
            return noOpComparator
        case .opus:
            return noOpComparator
        case .red:
            return noOpComparator
        }
    }
}

// MARK: - Private

private func noOpComparator(
    lhs: RTCRtpCodecCapability,
    rhs: RTCRtpCodecCapability
) -> Bool { true }

/// A function to compare two `RTCRtpCodecCapability` objects and determine
/// if the first should be ordered before the second for H264 prioritization.
///
/// - Parameters:
///   - lhs: The first `RTCRtpCodecCapability`.
///   - rhs: The second `RTCRtpCodecCapability`.
/// - Returns: `true` if `lhs` should be ordered before `rhs`, otherwise `false`.
private func h264Comparator(
    lhs: RTCRtpCodecCapability,
    rhs: RTCRtpCodecCapability
) -> Bool {
    let aMimeType = lhs.mimeType.lowercased()
    let bMimeType = rhs.mimeType.lowercased()

    // Return false if either mime type is not H264 (to keep original order for non-H264 codecs)
    guard aMimeType == "video/h264", bMimeType == "video/h264" else {
        return false
    }

    let aFmtpLine = lhs.fmtp
    let bFmtpLine = rhs.fmtp

    // Check for baseline profile-level-id=42
    let aIsBaseline = aFmtpLine.contains("profile-level-id=42")
    let bIsBaseline = bFmtpLine.contains("profile-level-id=42")
    if aIsBaseline && !bIsBaseline {
        return true
    }
    if !aIsBaseline && bIsBaseline {
        return false
    }

    // Check for packetization-mode=0 or absence of packetization-mode
    let aPacketizationMode0 = aFmtpLine.contains("packetization-mode=0") ||
        !aFmtpLine.contains("packetization-mode")
    let bPacketizationMode0 = bFmtpLine.contains("packetization-mode=0") ||
        !bFmtpLine.contains("packetization-mode")
    if aPacketizationMode0 && !bPacketizationMode0 {
        return true
    }
    if !aPacketizationMode0 && bPacketizationMode0 {
        return false
    }

    // If all checks are equal, keep the original order
    return false
}

/// A function to compare two `RTCRtpCodecCapability` objects and determine
/// if the first should be ordered before the second for VP9 prioritization.
///
/// - Parameters:
///   - lhs: The first `RTCRtpCodecCapability`.
///   - rhs: The second `RTCRtpCodecCapability`.
/// - Returns: `true` if `lhs` should be ordered before `rhs`, otherwise `false`.
private func vp9Comparator(
    lhs: RTCRtpCodecCapability,
    rhs: RTCRtpCodecCapability
) -> Bool {
    let aMimeType = lhs.mimeType.lowercased()
    let bMimeType = rhs.mimeType.lowercased()

    // Return false if either mime type is not VP9 (to keep original order for non-VP9 codecs)
    guard aMimeType == "video/vp9", bMimeType == "video/vp9" else {
        return false
    }

    let aFmtpLine = lhs.fmtp
    let bFmtpLine = rhs.fmtp

    // Check for profile-id=0 or absence of profile-id
    let aIsProfile0 = aFmtpLine.contains("profile-id=0") ||
        !aFmtpLine.contains("profile-id")
    let bIsProfile0 = bFmtpLine.contains("profile-id=0") ||
        !bFmtpLine.contains("profile-id")
    if aIsProfile0 && !bIsProfile0 {
        return true
    }
    if !aIsProfile0 && bIsProfile0 {
        return false
    }

    // If all checks are equal, keep the original order
    return false
}
