//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// AES-GCM variant used by ``EncryptionManager``.
///
/// - `'aes128Gcm'` (default): 16-byte keys.
/// - `'aes256Gcm'`: 32-byte keys.
public enum E2EEAlgorithm: Sendable {
    /// AES-128-GCM. Keys must be exactly 16 bytes.
    case aes128Gcm
    /// AES-256-GCM. Keys must be exactly 32 bytes.
    case aes256Gcm

    /// Native algorithm passed to `RTCEncryptionManager`.
    var rtcValue: RTCEncryptionAlgorithm {
        switch self {
        case .aes128Gcm:
            return .aes128Gcm
        case .aes256Gcm:
            return .aes256Gcm
        }
    }
}

/// One `e2ee.*` event from the native encryption manager.
///
/// Events include missing keys, decryption failures, and optional
/// performance reports. Optional fields are `nil` when the native event
/// omitted them.
public struct E2EEEvent: Sendable {
    /// Event name, for example `e2ee.missing_key`.
    public let name: String
    /// User id the event refers to.
    public let userId: String
    /// Replay-window grouping, when the event is track-specific.
    public let trackType: TrackType?
    /// Trailer key index, when present.
    public let keyIndex: Int?
    /// Protocol version, when present.
    public let version: Int?
    /// Human-readable failure reason, when present.
    public let reason: String?

    init(_ event: RTCE2eeEvent) {
        name = event.name
        userId = event.userId
        trackType = TrackType(rtcEncryptionTrackType: event.trackType)
        keyIndex = event.keyIndex?.intValue
        version = event.version?.intValue
        reason = event.reason
    }
}

/// Built-in framed AES-GCM implementation of ``E2EEManager``.
///
/// ## Overview
/// One manager holds keys and attaches encrypt/decrypt transforms to
/// `RTCRtpSender` / `RTCRtpReceiver` via StreamWebRTC's
/// `RTCEncryptionManager`. Construct it with a simple initializer, then
/// attach it to the call **before** join.
///
/// Keys are 16 bytes for AES-128-GCM and 32 bytes for AES-256-GCM.
/// `keyIndex` is an integer 0–255; one trailer byte carries it.
///
/// ## Example
/// ```swift
/// let e2ee = try EncryptionManager(userId: streamVideo.user.id)
/// try await call.setE2EEManager(e2ee)
/// try e2ee.setSharedKey(0, rawKey: keyBytes)
/// try await call.join()
/// ```
///
public final class EncryptionManager: E2EEManager, @unchecked Sendable {
    /// The local user's id, normally `streamVideo.user.id`.
    public let userId: String
    /// AES-GCM variant selected at construction.
    public let algorithm: E2EEAlgorithm

    private let native: RTCEncryptionManager
    private let eventForwarder: NativeE2EEEventForwarder
    private let eventSubject = PassthroughSubject<E2EEEvent, Never>()

    /// Publisher of native `e2ee.*` events (missing keys, decrypt failures).
    public var eventPublisher: AnyPublisher<E2EEEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    /// Native encoded transforms are always available in StreamWebRTC.
    public static var isSupported: Bool {
        RTCEncryptionManager.isSupported()
    }

    /// Creates a framed AES-GCM encryption manager for `userId`.
    ///
    /// - Parameters:
    ///   - userId: The local user's id, normally `streamVideo.user.id`.
    ///   - algorithm: AES-128-GCM (default) or AES-256-GCM.
    ///
    /// ## Example
    /// ```swift
    /// let e2ee = try EncryptionManager(userId: streamVideo.user.id)
    /// try await call.setE2EEManager(e2ee)
    /// try e2ee.setSharedKey(0, rawKey: keyBytes)
    /// ```
    ///
    /// - Throws: ``ClientError`` if `userId` is empty. Native construction
    ///   returns `nil` in that case.
    public init(
        userId: String,
        algorithm: E2EEAlgorithm = .aes128Gcm
    ) throws {
        guard let native = RTCEncryptionManager(
            userId: userId,
            algorithm: algorithm.rtcValue
        ) else {
            throw ClientError("userId must be a non-empty string.")
        }
        self.native = native
        self.userId = userId
        self.algorithm = algorithm
        let subject = eventSubject
        eventForwarder = NativeE2EEEventForwarder { subject.send($0) }
        native.delegate = eventForwarder
    }

    deinit {
        native.dispose()
    }

    /// Terminates native resources. The manager is unusable afterwards.
    public func dispose() {
        native.dispose()
    }

    /// Sets a per-user AES-GCM encryption key.
    ///
    /// - Parameters:
    ///   - userId: The key owner.
    ///   - keyIndex: An integer 0–255; one trailer byte carries it.
    ///   - rawKey: 16 bytes for AES-128-GCM, 32 for AES-256-GCM.
    /// - Throws: ``ClientError`` if `keyIndex` is outside 0–255 or `rawKey`
    ///   is the wrong length; native errors if the manager is disposed.
    public func setKey(
        _ userId: String,
        keyIndex: Int,
        rawKey: Data
    ) throws {
        try validateKeyIndex(keyIndex)
        try validateKeyLength(rawKey)
        try native.setKey(userId, keyIndex: Int32(keyIndex), rawKey: rawKey)
    }

    /// Sets a fallback key for any user without a per-user key.
    ///
    /// - Parameters:
    ///   - keyIndex: An integer 0–255; one trailer byte carries it.
    ///   - rawKey: 16 bytes for AES-128-GCM, 32 for AES-256-GCM.
    /// - Throws: ``ClientError`` if `keyIndex` is outside 0–255 or `rawKey`
    ///   is the wrong length; native errors if the manager is disposed.
    public func setSharedKey(_ keyIndex: Int, rawKey: Data) throws {
        try validateKeyIndex(keyIndex)
        try validateKeyLength(rawKey)
        try native.setSharedKey(Int32(keyIndex), rawKey: rawKey)
    }

    /// Removes a per-user key at `keyIndex`.
    ///
    /// - Parameters:
    ///   - userId: The key owner.
    ///   - keyIndex: An integer 0–255.
    /// - Throws: ``ClientError`` if `keyIndex` is outside 0–255; native
    ///   errors if the manager is disposed.
    public func removeKey(_ userId: String, keyIndex: Int) throws {
        try validateKeyIndex(keyIndex)
        try native.removeKey(userId, keyIndex: Int32(keyIndex))
    }

    /// Removes every per-user key for `userId`.
    ///
    /// - Parameter userId: The key owner.
    /// - Throws: Native errors if the manager is disposed.
    public func removeAllKeys(_ userId: String) throws {
        try native.removeAllKeys(userId)
    }

    /// Removes the shared fallback key at `keyIndex`.
    ///
    /// - Parameter keyIndex: An integer 0–255.
    /// - Throws: ``ClientError`` if `keyIndex` is outside 0–255; native
    ///   errors if the manager is disposed.
    public func removeSharedKey(_ keyIndex: Int) throws {
        try validateKeyIndex(keyIndex)
        try native.removeSharedKey(Int32(keyIndex))
    }

    /// Attaches an encryptor to `sender`.
    ///
    /// See ``E2EEManager/encrypt(_:codec:trackType:)``.
    public func encrypt(
        _ sender: RTCRtpSender,
        codec: String?,
        trackType: TrackType?
    ) throws {
        try native.encrypt(
            sender,
            codec: codec,
            trackType: trackType?.rtcEncryptionTrackType
        )
    }

    /// Attaches a decryptor to `receiver`.
    ///
    /// See ``E2EEManager/decrypt(_:userId:trackType:)``.
    public func decrypt(
        _ receiver: RTCRtpReceiver,
        userId: String,
        trackType: TrackType?
    ) throws {
        try native.decrypt(
            receiver,
            userId: userId,
            trackType: trackType?.rtcEncryptionTrackType
        )
    }

    /// Enables or disables native encode/decode performance reports.
    ///
    /// - Parameter enabled: Pass `true` to start emitting `e2ee.perf_report`
    ///   events on ``eventPublisher``.
    /// - Throws: Native errors if the manager is disposed.
    public func enablePerformanceReporting(_ enabled: Bool) throws {
        try native.enablePerformanceReporting(enabled)
    }

    /// Requests a snapshot of currently loaded keys as an `e2ee.key_state`
    /// event on ``eventPublisher``.
    ///
    /// - Throws: Native errors if the manager is disposed.
    public func requestKeyState() throws {
        try native.requestKeyState()
    }

    private func validateKeyLength(_ rawKey: Data) throws {
        let expected = algorithm == .aes256Gcm ? 32 : 16
        guard rawKey.count == expected else {
            throw ClientError(
                "Key must be exactly \(expected) bytes (\(algorithm == .aes256Gcm ? "AES-256" : "AES-128"))."
            )
        }
    }

    private func validateKeyIndex(_ keyIndex: Int) throws {
        guard (0...255).contains(keyIndex) else {
            throw ClientError(
                "keyIndex must be an integer between 0 and 255, got \(keyIndex)."
            )
        }
    }
}

extension TrackType {
    /// Native `RTCEncryptionTrackType`. Screenshare audio is not a distinct
    /// Swift `TrackType` yet; those tracks encrypt as `.audio`.
    var rtcEncryptionTrackType: NSNumber? {
        let value: RTCEncryptionTrackType
        switch self {
        case .audio:
            value = .audio
        case .video:
            value = .video
        case .screenshare:
            value = .screenshare
        default:
            return nil
        }
        return NSNumber(value: value.rawValue)
    }

    /// Maps a native track-type number back to ``TrackType``.
    ///
    /// Native `.screenshareAudio` collapses to `.audio` because Swift has
    /// no dedicated screenshare-audio case.
    init?(rtcEncryptionTrackType number: NSNumber?) {
        guard
            let number,
            let value = RTCEncryptionTrackType(rawValue: number.intValue)
        else {
            return nil
        }
        switch value {
        case .audio, .screenshareAudio:
            self = .audio
        case .video:
            self = .video
        case .screenshare:
            self = .screenshare
        @unknown default:
            return nil
        }
    }
}

extension VideoCodec {
    /// Exact lowercase pin for framed AES-GCM. `nil` lets native read the frame.
    var e2eeCodecPin: String? {
        switch self {
        case .vp8, .vp9, .h264:
            return rawValue
        default:
            return nil
        }
    }
}

extension AudioCodec {
    /// Exact lowercase pin for framed AES-GCM. `nil` lets native read the frame.
    var e2eeCodecPin: String? {
        switch self {
        case .opus:
            return rawValue
        default:
            return nil
        }
    }
}

/// Forwards native `RTCEncryptionManagerDelegate` callbacks onto Combine.
private final class NativeE2EEEventForwarder: NSObject, RTCEncryptionManagerDelegate {
    private let handler: (E2EEEvent) -> Void

    init(handler: @escaping (E2EEEvent) -> Void) {
        self.handler = handler
    }

    func encryptionManager(
        _ manager: RTCEncryptionManager,
        didReceive event: RTCE2eeEvent
    ) {
        let mapped = E2EEEvent(event)
        let detail = [
            mapped.trackType.map { "trackType:\($0)" },
            mapped.keyIndex.map { "keyIndex:\($0)" },
            mapped.reason.map { "reason:\($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        let message = "E2EE \(mapped.name) userId:\(mapped.userId) \(detail)"
            .trimmingCharacters(in: .whitespaces)
        if event.type.logsAsWarning {
            log.warning(message, subsystems: .webRTC)
        } else {
            log.debug(message, subsystems: .webRTC)
        }
        handler(mapped)
    }
}

private extension RTCE2eeEventType {
    var logsAsWarning: Bool {
        switch self {
        case .unencryptedFrame,
             .unsupportedVersion,
             .encryptionFailed,
             .decryptionFailed,
             .missingKey,
             .decryptionStalled:
            return true
        default:
            return false
        }
    }
}
