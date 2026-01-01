//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extension providing utility properties for `RTCRtpCodecCapability`.
extension RTCRtpCodecCapability {
    /// A formatted string representation of codec parameters (`fmtp`).
    ///
    /// Converts the codec parameters dictionary into a single string where
    /// each key-value pair is separated by `=` and entries are joined by `;`.
    var fmtp: String {
        parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
    }
}

/// Extension providing utility methods for sequences of `RTCRtpCodecCapability`.
extension Sequence where Element == RTCRtpCodecCapability {

    /// Retrieves the baseline codec for a given video codec.
    ///
    /// - Parameter videoCodec: The video codec to filter and prioritize.
    /// - Returns: The most suitable `RTCRtpCodecCapability` for the given codec.
    func baseline(for videoCodec: VideoCodec) -> RTCRtpCodecCapability? {
        filter { $0.name.lowercased() == videoCodec.rawValue }
            .sorted(by: videoCodec.baselineComparator)
            .first
    }

    /// Retrieves the baseline codec for a given audio codec.
    ///
    /// - Parameter audioCodec: The audio codec to filter and prioritize.
    /// - Returns: The most suitable `RTCRtpCodecCapability` for the given codec.
    func baseline(for audioCodec: AudioCodec) -> RTCRtpCodecCapability? {
        filter { $0.name.lowercased() == audioCodec.rawValue }
            .sorted(by: audioCodec.baselineComparator)
            .first
    }
}

/// Extension providing prioritization rules for `VideoCodec`.
extension VideoCodec {
    /// A comparator used to prioritize baseline codec capabilities.
    ///
    /// The comparator defines rules for ordering codecs, where codecs with
    /// desirable properties (e.g., baseline profiles) are prioritized.
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
        case .unknown:
            return noOpComparator
        }
    }
}

/// Extension providing prioritization rules for `AudioCodec`.
extension AudioCodec {
    /// A comparator used to prioritize baseline codec capabilities.
    ///
    /// The comparator currently applies no specific ordering for audio codecs.
    fileprivate var baselineComparator: (RTCRtpCodecCapability, RTCRtpCodecCapability) -> Bool {
        switch self {
        case .unknown:
            return noOpComparator
        case .opus:
            return noOpComparator
        case .red:
            return noOpComparator
        }
    }
}

// MARK: - Private

/// A no-op comparator that maintains the original codec order.
///
/// - Parameters:
///   - lhs: The first `RTCRtpCodecCapability`.
///   - rhs: The second `RTCRtpCodecCapability`.
/// - Returns: Always returns `true`, maintaining the original order.
private func noOpComparator(
    lhs: RTCRtpCodecCapability,
    rhs: RTCRtpCodecCapability
) -> Bool { true }

/// A comparator for prioritizing H264 codec capabilities.
///
/// - Parameters:
///   - lhs: The first `RTCRtpCodecCapability`.
///   - rhs: The second `RTCRtpCodecCapability`.
/// - Returns: `true` if `lhs` is prioritized over `rhs`, otherwise `false`.
private func h264Comparator(
    lhs: RTCRtpCodecCapability,
    rhs: RTCRtpCodecCapability
) -> Bool {
    let aMimeType = lhs.mimeType.lowercased()
    let bMimeType = rhs.mimeType.lowercased()

    // Ensure comparison only applies to H264 codecs.
    guard aMimeType == "video/h264", bMimeType == "video/h264" else {
        return false
    }

    let aFmtpLine = lhs.fmtp
    let bFmtpLine = rhs.fmtp

    // Prioritize codecs with baseline profile-level-id=42.
    let aIsBaseline = aFmtpLine.contains("profile-level-id=42")
    let bIsBaseline = bFmtpLine.contains("profile-level-id=42")
    if aIsBaseline && !bIsBaseline {
        return true
    }
    if !aIsBaseline && bIsBaseline {
        return false
    }

    // Prioritize codecs with packetization-mode=0 or none.
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

    // Maintain original order if all conditions are equal.
    return false
}

/// A comparator for prioritizing VP9 codec capabilities.
///
/// - Parameters:
///   - lhs: The first `RTCRtpCodecCapability`.
///   - rhs: The second `RTCRtpCodecCapability`.
/// - Returns: `true` if `lhs` is prioritized over `rhs`, otherwise `false`.
private func vp9Comparator(
    lhs: RTCRtpCodecCapability,
    rhs: RTCRtpCodecCapability
) -> Bool {
    let aMimeType = lhs.mimeType.lowercased()
    let bMimeType = rhs.mimeType.lowercased()

    // Ensure comparison only applies to VP9 codecs.
    guard aMimeType == "video/vp9", bMimeType == "video/vp9" else {
        return false
    }

    let aFmtpLine = lhs.fmtp
    let bFmtpLine = rhs.fmtp

    // Prioritize codecs with profile-id=0 or none.
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

    // Maintain original order if all conditions are equal.
    return false
}
