//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class MediaAdapter {
    private let queue = UnfairQueue()
    private let disposableBag = DisposableBag()
    private let peerConnection: RTCPeerConnection
    private let videoOptions: VideoOptions

    private var screenShares: [String: RTCMediaStream] = [:]
    private var video: [String: RTCMediaStream] = [:]
    private var audio: [String: RTCMediaStream] = [:]
    private var published: [TrackType: RTCMediaSenderOrTransceiver] = [:]

    init(
        peerConnection: RTCPeerConnection,
        videoOptions: VideoOptions
    ) {
        self.peerConnection = peerConnection
        self.videoOptions = videoOptions

        peerConnection
            .publisher(eventType: RTCPeerConnection.AddedStreamEvent.self)
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: RTCPeerConnection.RemovedStreamEvent.self)
            .sink { [weak self] in self?.remove($0.stream) }
            .store(in: disposableBag)
    }

    deinit {
        close()
    }

    // MARK: - Query Media tracks

    func screenShareTrack(with prefix: String) -> RTCVideoTrack? {
        mediaTrack(of: .screenShare, prefix: prefix)
    }

    func videoTrack(with prefix: String) -> RTCVideoTrack? {
        mediaTrack(of: .video, prefix: prefix)
    }

    func audioTrack(with prefix: String) -> RTCAudioTrack? {
        mediaTrack(of: .audio, prefix: prefix)
    }

    func publisher<V: RTCMediaSenderOrTransceiver>(for trackType: TrackType) -> V? {
        queue.sync { published[trackType] } as? V
    }

    func publishes(_ trackType: TrackType) -> Bool {
        queue.sync { published[trackType] } != nil
    }

    // MARK: - Query mid

    func mid(for type: TrackType) -> String? {
        switch type {
        case .video, .screenShare:
            return queue.sync { published[type] }?.mid
        default:
            return nil
        }
    }

    // MARK: - Publishing

    func publish(
        _ track: RTCMediaStreamTrack,
        trackType: TrackType,
        streamIds: [String]
    ) {
        if let sender = peerConnection.add(track, streamIds: streamIds) {
            queue.sync {
                published[trackType] = sender
            }
        } else {
            log.error(
                """
                "Unable to publish track
                Track ID: \(track.trackId)
                Track Type: \(trackType)
                Stream IDs: \(streamIds.joined(separator: ","))
                """
            )
        }
    }

    func publish(
        _ track: RTCMediaStreamTrack,
        trackType: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String]
    ) {
        let transceiverInit = RTCRtpTransceiverInit(
            trackType: trackType,
            direction: direction,
            streamIds: streamIds,
            codecs: videoOptions.supportedCodecs
        )

        if
            trackType == .screenShare,
            let publisher = queue.sync({ published[.screenShare] }) {
            publisher.stopInternal()
            queue.sync { screenShares }.values.forEach {
                peerConnection.remove($0)
            }

            queue.sync {
                published[.screenShare] = nil
                screenShares = [:]
            }
        }

        if let sender = peerConnection.addTransceiver(with: track, init: transceiverInit) {
            queue.sync {
                published[trackType] = sender
            }
        } else {
            log.error(
                """
                "Unable to publish track
                Track ID: \(track.trackId)
                Track Type: \(trackType)
                Stream IDs: \(transceiverInit.streamIds.joined(separator: ","))
                """
            )
        }
    }

    func changePublishQuality(
        for trackType: TrackType,
        enabledRids: Set<String>
    ) {
        guard
            trackType == .video,
            let transceiver: RTCRtpTransceiver = publisher(for: trackType)
        else {
            return
        }

        let params = transceiver.sender.parameters
        let updatedEncodings = params.encodings.map { encoding in
            let updatedEncoding = encoding
            let shouldEnable = enabledRids.contains(encoding.rid ?? UUID().uuidString)
            if updatedEncoding.isActive != shouldEnable {
                updatedEncoding.isActive = shouldEnable
            }
            return updatedEncoding
        }

        if updatedEncodings != params.encodings {
            log.debug("Updating publish quality with encodings \(updatedEncodings)")
            params.encodings = updatedEncodings
            transceiver.sender.parameters = params
        }
    }

    // MARK: - Closing

    func close() {
        queue.sync { published.values }.forEach { $0.stopInternal() }
    }

    // MARK: - Private Helpers
    
    private func add(_ stream: RTCMediaStream) {
        switch stream.trackType {
        case .screenShare:
            queue.sync { screenShares[stream.streamId] = stream }
        case .video:
            queue.sync { video[stream.streamId] = stream }
        case .audio:
            queue.sync { audio[stream.streamId] = stream }
        default:
            break
        }
    }

    private func remove(_ stream: RTCMediaStream) {
        switch stream.trackType {
        case .screenShare:
            queue.sync { screenShares[stream.streamId] = nil }
        case .video:
            queue.sync { video[stream.streamId] = nil }
        case .audio:
            queue.sync { audio[stream.streamId] = nil }
        default:
            break
        }
    }

    private func mediaTrack<V: RTCMediaStreamTrack>(
        of type: TrackType,
        prefix: String
    ) -> V? {
        let elements: [RTCMediaStream] = {
            switch type {
            case .screenShare:
                return Array(queue.sync { screenShares }.values)
            case .video:
                return Array(queue.sync { video }.values)
            case .audio:
                return Array(queue.sync { audio }.values)
            default:
                return []
            }
        }()

        guard !elements.isEmpty else {
            return nil
        }

        let element = elements.first { $0.streamId.contains(prefix) }

        switch type {
        case .screenShare:
            return element?.videoTracks.first as? V
        case .video:
            return element?.videoTracks.first as? V
        case .audio:
            return element?.audioTracks.first as? V
        default:
            return nil
        }
    }
}

protocol RTCMediaSenderOrTransceiver {
    var mid: String { get }
    func stopInternal()
}

extension RTCRtpSender: RTCMediaSenderOrTransceiver {
    var mid: String { "" }

    func stopInternal() { /* No-op */ }
}

extension RTCRtpTransceiver: RTCMediaSenderOrTransceiver {}
