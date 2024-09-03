//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class VideoMediaAdapter: MediaAdapting, @unchecked Sendable {

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private let localMediaManager: LocalMediaAdapting

    private let disposableBag = DisposableBag()
    private let queue = UnfairQueue()

    private var streams: [RTCMediaStream] = []

    let subject: PassthroughSubject<TrackEvent, Never>

    var localTrack: RTCMediaStreamTrack? {
        (localMediaManager as? LocalVideoMediaAdapter)?.localTrack
    }

    var mid: String? {
        (localMediaManager as? LocalVideoMediaAdapter)?.mid
    }

    convenience init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.init(
            sessionID: sessionID,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: LocalVideoMediaAdapter(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                subject: subject
            ),
            subject: subject
        )
    }

    init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        localMediaManager: LocalMediaAdapting,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.localMediaManager = localMediaManager
        self.subject = subject

        peerConnection
            .publisher(eventType: RTCPeerConnection.AddedStreamEvent.self)
            .filter { $0.stream.trackType == .video }
            .sink { [weak self] in self?.add($0.stream) }
            .store(in: disposableBag)

        peerConnection
            .publisher(eventType: RTCPeerConnection.RemovedStreamEvent.self)
            .filter { $0.stream.trackType == .video }
            .sink { [weak self] in self?.remove($0.stream) }
            .store(in: disposableBag)
    }

    // MARK: - MediaAdapting

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await localMediaManager.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        try await localMediaManager.didUpdateCallSettings(settings)
    }

    // MARK: - Video

    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }

        try await localVideoMediaManager.didUpdateCameraPosition(position)
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        localVideoMediaManager.setVideoFilter(videoFilter)
    }

    func zoom(by factor: CGFloat) throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        try localVideoMediaManager.zoom(by: factor)
    }

    func focus(at point: CGPoint) throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        try localVideoMediaManager.focus(at: point)
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        try localVideoMediaManager.addVideoOutput(videoOutput)
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        try localVideoMediaManager.removeVideoOutput(videoOutput)
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        try localVideoMediaManager.addCapturePhotoOutput(capturePhotoOutput)
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        guard
            let localVideoMediaManager = localMediaManager as? LocalVideoMediaAdapter
        else {
            return
        }
        try localVideoMediaManager.removeCapturePhotoOutput(capturePhotoOutput)
    }

    func changePublishQuality(
        with activeEncodings: Set<String>
    ) {
        (localMediaManager as? LocalVideoMediaAdapter)?
            .changePublishQuality(with: activeEncodings)
    }

    // MARK: - Observers

    private func add(_ stream: RTCMediaStream) {
        queue.sync { streams.append(stream) }
        if let videoTrack = stream.videoTracks.first {
            subject.send(
                .added(
                    id: stream.trackId,
                    trackType: .video,
                    track: videoTrack
                )
            )
        }
    }

    private func remove(_ stream: RTCMediaStream) {
        queue.sync {
            streams = streams.filter { $0.streamId != stream.streamId }
        }
        if let videoTrack = stream.videoTracks.first {
            subject.send(
                .removed(
                    id: stream.streamId,
                    trackType: .video,
                    track: videoTrack
                )
            )
        }
    }
}
