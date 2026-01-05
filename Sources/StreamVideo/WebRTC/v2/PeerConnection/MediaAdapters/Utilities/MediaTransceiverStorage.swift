//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A thread-safe storage for managing `RTCRtpTransceiver` instances by key.
///
/// `MediaTransceiverStorage` provides a synchronized way to store and retrieve
/// transceivers associated with a specific track type (e.g., audio or video).
/// It uses a nested `Key` structure to hash and identify items, ensuring
/// safe access and modifications across multiple threads.
final class MediaTransceiverStorage<KeyType: Hashable>: Sequence, CustomStringConvertible, @unchecked Sendable {

    /// The type of track (e.g., audio, video, screen share) that this storage manages.
    private let trackType: TrackType

    /// Internal dictionary storing `RTCRtpTransceiver` instances by a hashable key.
    private var storage: [KeyType: (transceiver: RTCRtpTransceiver, track: RTCMediaStreamTrack)] = [:]

    /// A serial queue used to synchronize access to the storage.
    private let storageQueue = UnfairQueue()

    /// A textual representation of the active and inactive transceivers in the storage.
    ///
    /// Lists all active and inactive transceivers, showing their associated keys
    /// and track IDs for debugging and informational purposes.
    var description: String {
        let storageSnapshot = storageQueue.sync { self.storage }
        let active = storageSnapshot
            .filter { $1.transceiver.sender.track?.isEnabled == true }
            .map { "\($0.key) → trackOnTransceiver:\($0.value.transceiver.sender.track != nil) trackID:\($0.value.track.trackId)" }
            .joined(separator: "\n")
        let inactive = storageSnapshot
            .filter { $1.transceiver.sender.track == nil }
            .map { "\($0.key)" }
            .joined(separator: "\n")

        return """
        MediaTransceiverStorage for type: \(trackType)
            Active:
                \(active)
            Inactive:
                \(inactive)
        """
    }

    var isEmpty: Bool { storage.isEmpty }

    var count: Int { storage.count }

    /// Initializes a new `MediaTransceiverStorage` for a specific track type.
    ///
    /// - Parameter trackType: The type of track (e.g., audio, video, screen share).
    init(for trackType: TrackType) {
        self.trackType = trackType
    }

    /// Deinitializes the storage, ensuring all transceivers are stopped and cleared.
    deinit {
        storageQueue.sync {
            storage.forEach {
                $0.value.transceiver.sender.track = nil
            }
            storage.removeAll()
        }
    }

    /// Retrieves a transceiver associated with a specific key.
    ///
    /// - Parameter key: The key used to look up the transceiver.
    /// - Returns: The `RTCRtpTransceiver` associated with the key, or `nil` if not found.
    func get(for key: KeyType) -> (transceiver: RTCRtpTransceiver, track: RTCMediaStreamTrack)? {
        storageQueue.sync {
            storage[key]
        }
    }

    /// Associates a transceiver with a specific key, replacing any existing entry.
    ///
    /// - Parameters:
    ///   - value: The transceiver to store, or `nil` to remove the key from storage.
    ///   - key: The key used to associate with the transceiver.
    func set(_ value: RTCRtpTransceiver, track: RTCMediaStreamTrack, for key: KeyType) {
        if contains(key: key) {
            log.warning("TransceiverStorage for trackType: \(trackType) will overwrite existing value for key: \(key).")
        }
        storageQueue.sync {
            storage[key] = (value, track)
        }
    }

    /// Checks whether the storage contains a transceiver for a specific key.
    ///
    /// - Parameter key: The key to check for existence.
    /// - Returns: `true` if the key exists in the storage, `false` otherwise.
    func contains(key: KeyType) -> Bool {
        storageQueue.sync { storage[key] != nil }
    }

    /// Removes all transceivers from the storage.
    ///
    /// Ensures that all transceivers are stopped and their associated tracks are cleared
    /// before removing them from the storage.
    func removeAll() {
        storageQueue.sync {
            storage.forEach { $0.value.transceiver.sender.track = nil }
            storage.removeAll()
        }
    }

    /// Retrieves the key associated with a specific transceiver's receiver.
    ///
    /// - Parameter value: The `RTCRtpReceiver` whose associated key is requested.
    /// - Returns: The key associated with the receiver, or `nil` if not found.
    func key(for value: RTCRtpReceiver) -> KeyType? {
        storageQueue.sync { storage.first(where: { $0.value.transceiver === value })?.key }
    }

    // MARK: Sequence

    /// Makes an iterator for iterating over the storage.
    ///
    /// - Returns: An iterator for `(key: Key, value: RTCRtpTransceiver)` pairs.
    func makeIterator() -> AnyIterator<(
        key: KeyType,
        value: (transceiver: RTCRtpTransceiver, track: RTCMediaStreamTrack)
    )> {
        let elements = storageQueue
            .sync { storage }
            .map { (key: KeyType, value: (transceiver: RTCRtpTransceiver, track: RTCMediaStreamTrack)) in
                (key: key, value: value)
            }
        return AnyIterator(elements.makeIterator())
    }
}
