//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class MediaTransceiverStorage: Sequence, CustomStringConvertible {

    private let trackType: TrackType
    private var storage: [AnyHashable: RTCRtpTransceiver] = [:]
    private let storageQueue = UnfairQueue()

    var description: String {
        let storage: [AnyHashable: RTCRtpTransceiver] = storageQueue.sync { self.storage }
        let active = storage
            .filter { $1.sender.track?.isEnabled == true }
            .compactMap { $0 }
            .map { "\($0.key.base) → \($0.value.sender.track?.trackId ?? "unavailable trackId")" }
            .joined(separator: "\n")
        let inactive = storage
            .filter { $1.sender.track?.isEnabled != true }
            .compactMap { $0 }
            .map { "\($0.key.base)" }
            .joined(separator: "\n")

        return """
        MediaTransceiverStorage for type:\(trackType)
            Active:
                \(active)
        
            Inactive:
                \(inactive)
        """
    }

    init(for trackType: TrackType) {
        self.trackType = trackType
    }

    deinit {
        storage.forEach {
            $0.value.sender.track = nil
            $0.value.stopInternal()
        }
        storage.removeAll()
    }

    func get<Key: Hashable>(for key: Key) -> RTCRtpTransceiver? {
        storageQueue.sync {
            storage[AnyHashable(key)]
        }
    }

    func set<Key: Hashable>(_ value: RTCRtpTransceiver?, for key: Key) {
        if contains(key: key) {
            log.warning("TransceiverStorage for trackType:\(trackType) will overwrite existing value for key:\(key).")
        }
        storageQueue.sync {
            storage[AnyHashable(key)] = value
        }
    }

    func contains<Key: Hashable>(key: Key) -> Bool {
        storageQueue.sync { storage[AnyHashable(key)] != nil }
    }

    func removeAll() {
        storageQueue.sync {
            storage.forEach {
                $0.value.sender.track = nil
                $0.value.stopInternal()
            }
            storage.removeAll()
        }
    }

    func key<Key: Hashable>(for value: RTCRtpReceiver) -> Key? {
        storageQueue.sync { storage.first(where: { $0.value === value })?.key.base as? Key }
    }

    // MARK: Sequence

    func makeIterator() -> AnyIterator<(key: AnyHashable, value: RTCRtpTransceiver)> {
        let elements = storageQueue.sync { storage }
        return AnyIterator(elements.makeIterator())
    }
}
