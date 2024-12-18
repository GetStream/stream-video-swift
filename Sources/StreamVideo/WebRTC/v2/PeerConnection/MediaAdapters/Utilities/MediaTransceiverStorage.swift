//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A thread-safe storage for managing `RTCRtpTransceiver` instances by key.
///
/// `MediaTransceiverStorage` provides a synchronized way to store and retrieve
/// transceivers associated with a specific track type (e.g., audio or video).
/// It uses a nested `Key` structure to hash and identify items, ensuring
/// safe access and modifications across multiple threads.
final class MediaTransceiverStorage<KeyType: Hashable>: Sequence, CustomStringConvertible {

    /// The type of track (e.g., audio, video, screen share) that this storage manages.
    private let trackType: TrackType

    /// Internal dictionary storing `RTCRtpTransceiver` instances by a hashable key.
    private var storage: [KeyType: RTCRtpTransceiver] = [:]

    /// A serial queue used to synchronize access to the storage.
    private let storageQueue = UnfairQueue()

    /// A textual representation of the active and inactive transceivers in the storage.
    ///
    /// Lists all active and inactive transceivers, showing their associated keys
    /// and track IDs for debugging and informational purposes.
    var description: String {
        let storageSnapshot = storageQueue.sync { self.storage }
        let active = storageSnapshot
            .filter { $1.sender.track?.isEnabled == true }
            .map { "\($0.key) → \($0.value.sender.track?.trackId ?? "unavailable trackId")" }
            .joined(separator: "\n")
        let inactive = storageSnapshot
            .filter { $1.sender.track?.isEnabled != true }
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
                $0.value.sender.track = nil
            }
            storage.removeAll()
        }
    }

    /// Retrieves a transceiver associated with a specific key.
    ///
    /// - Parameter key: The key used to look up the transceiver.
    /// - Returns: The `RTCRtpTransceiver` associated with the key, or `nil` if not found.
    func get(for key: KeyType) -> RTCRtpTransceiver? {
        storageQueue.sync {
            storage[key]
        }
    }

    /// Associates a transceiver with a specific key, replacing any existing entry.
    ///
    /// - Parameters:
    ///   - value: The transceiver to store, or `nil` to remove the key from storage.
    ///   - key: The key used to associate with the transceiver.
    func set(_ value: RTCRtpTransceiver?, for key: KeyType) {
        if contains(key: key) {
            log.warning("TransceiverStorage for trackType: \(trackType) will overwrite existing value for key: \(key).")
        }
        storageQueue.sync {
            storage[key] = value
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
            storage.forEach { $0.value.sender.track = nil }
            storage.removeAll()
        }
    }

    /// Retrieves the key associated with a specific transceiver's receiver.
    ///
    /// - Parameter value: The `RTCRtpReceiver` whose associated key is requested.
    /// - Returns: The key associated with the receiver, or `nil` if not found.
    func key(for value: RTCRtpReceiver) -> KeyType? {
        storageQueue.sync { storage.first(where: { $0.value === value })?.key }
    }

    // MARK: Sequence

    /// Makes an iterator for iterating over the storage.
    ///
    /// - Returns: An iterator for `(key: Key, value: RTCRtpTransceiver)` pairs.
    func makeIterator() -> AnyIterator<(
        key: KeyType,
        value: RTCRtpTransceiver
    )> {
        let elements = storageQueue
            .sync { storage }
            .map { (key: KeyType, value: RTCRtpTransceiver) in
                (key: key, value: value)
            }
        return AnyIterator(elements.makeIterator())
    }
}
