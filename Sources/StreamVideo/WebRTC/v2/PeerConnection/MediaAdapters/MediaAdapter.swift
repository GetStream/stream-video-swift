//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class MediaAdapter {

    private let audioMediaAdapter: AudioMediaAdapter
    private let videoMediaAdapter: VideoMediaAdapter
    private let screenShareMediaAdapter: ScreenShareMediaAdapter
    private let subject: PassthroughSubject<TrackEvent, Never>

    var trackPublisher: AnyPublisher<TrackEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    init(
        sessionID: String,
        peerConnectionType: PeerConnectionType,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        audioSession: AudioSession,
        screenShareSessionProvider: ScreenShareSessionProvider
    ) {
        let subject = PassthroughSubject<TrackEvent, Never>()
        self.subject = subject

        switch peerConnectionType {
        case .subscriber:
            audioMediaAdapter = .init(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                localMediaManager: LocalNoOpMediaAdapter(subject: subject),
                subject: subject,
                audioSession: audioSession
            )

            videoMediaAdapter = .init(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                localMediaManager: LocalNoOpMediaAdapter(subject: subject),
                subject: subject
            )

            screenShareMediaAdapter = .init(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                localMediaManager: LocalNoOpMediaAdapter(subject: subject),
                subject: subject
            )

        case .publisher:
            audioMediaAdapter = .init(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                subject: subject,
                audioSession: audioSession
            )

            videoMediaAdapter = .init(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                subject: subject
            )

            screenShareMediaAdapter = .init(
                sessionID: sessionID,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                subject: subject,
                screenShareSessionProvider: screenShareSessionProvider
            )
        }
    }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await audioMediaAdapter.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )

        try await videoMediaAdapter.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )

        try await screenShareMediaAdapter.setUp(
            with: settings,
            ownCapabilities: ownCapabilities
        )
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [audioMediaAdapter, videoMediaAdapter, screenShareMediaAdapter] group in
            group.addTask {
                try await audioMediaAdapter.didUpdateCallSettings(settings)
            }

            group.addTask {
                try await videoMediaAdapter.didUpdateCallSettings(settings)
            }

            group.addTask {
                try await screenShareMediaAdapter.didUpdateCallSettings(settings)
            }

            while try await group.next() != nil {}
        }
    }

    func localTrack(of type: TrackType) -> RTCMediaStreamTrack? {
        switch type {
        case .audio:
            return audioMediaAdapter.localTrack
        case .video:
            return videoMediaAdapter.localTrack
        case .screenshare:
            return screenShareMediaAdapter.localTrack
        default:
            return nil
        }
    }

    func mid(for type: TrackType) -> String? {
        switch type {
        case .audio:
            return audioMediaAdapter.mid
        case .video:
            return videoMediaAdapter.mid
        case .screenshare:
            return screenShareMediaAdapter.mid
        default:
            return nil
        }
    }

    // MARK: - Audio

    func didUpdateAudioSessionState(_ isEnabled: Bool) async {
        await audioMediaAdapter.didUpdateAudioSessionState(isEnabled)
    }

    func didUpdateAudioSessionSpeakerState(
        _ isEnabled: Bool,
        with audioSessionEnabled: Bool
    ) async {
        await audioMediaAdapter.didUpdateAudioSessionSpeakerState(
            isEnabled,
            with: audioSessionEnabled
        )
    }

    // MARK: - Video

    func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        try await videoMediaAdapter.didUpdateCameraPosition(position)
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        videoMediaAdapter.setVideoFilter(videoFilter)
    }

    func zoom(by factor: CGFloat) throws {
        try videoMediaAdapter.zoom(by: factor)
    }

    func focus(at point: CGPoint) throws {
        try videoMediaAdapter.focus(at: point)
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try videoMediaAdapter.addVideoOutput(videoOutput)
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        try videoMediaAdapter.removeVideoOutput(videoOutput)
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try videoMediaAdapter.addCapturePhotoOutput(capturePhotoOutput)
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        try videoMediaAdapter.removeCapturePhotoOutput(capturePhotoOutput)
    }

    func changePublishQuality(
        with activeEncodings: Set<String>
    ) {
        videoMediaAdapter.changePublishQuality(with: activeEncodings)
    }

    // MARK: - ScreenSharing

    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability]
    ) async throws {
        try await screenShareMediaAdapter.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )
    }

    func stopScreenSharing() async throws {
        try await screenShareMediaAdapter.stopScreenSharing()
    }
}
