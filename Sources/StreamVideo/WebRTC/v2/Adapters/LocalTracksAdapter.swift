//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class LocalTracksAdapter {

    private let peerConnectionFactory: PeerConnectionFactory
    private let hasCapabilityProvider: (OwnCapability) -> Bool

    private let tracksStorageQueue = UnfairQueue()
    private var trackStorage: [TrackType: RTCMediaStreamTrack] = [:]

    private var videoCapturer: VideoCapturer?
    private var screenShareCapturer: VideoCapturing?
    private lazy var audioSession = AudioSession()

    var audioTrack: RTCAudioTrack? {
        get { tracksStorageQueue.sync { trackStorage[.audio] } as? RTCAudioTrack }
        set { tracksStorageQueue.sync { trackStorage[.audio] = newValue } }
    }

    var videoTrack: RTCVideoTrack? {
        get { tracksStorageQueue.sync { trackStorage[.video] } as? RTCVideoTrack }
        set { tracksStorageQueue.sync { trackStorage[.video] = newValue } }
    }

    var screenShareTrack: RTCVideoTrack? {
        get { tracksStorageQueue.sync { trackStorage[.screenShare] } as? RTCVideoTrack }
        set { tracksStorageQueue.sync { trackStorage[.screenShare] = newValue } }
    }

    init(
        peerConnectionFactory: PeerConnectionFactory,
        hasCapabilityProvider: @escaping (OwnCapability) -> Bool
    ) {
        self.peerConnectionFactory = peerConnectionFactory
        self.hasCapabilityProvider = hasCapabilityProvider
    }

    func setupIfRequired(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        videoConfig: VideoConfig
    ) {
        if hasCapabilityProvider(.sendAudio), audioTrack == nil {
            audioSession.configure(
                audioOn: callSettings.audioOn,
                speakerOn: callSettings.speakerOn
            )
            let audioConstrains = RTCMediaConstraints(
                mandatoryConstraints: nil,
                optionalConstraints: nil
            )
            let audioSource = peerConnectionFactory.makeAudioSource(audioConstrains)
            audioTrack = peerConnectionFactory.makeAudioTrack(source: audioSource)
        }

        if hasCapabilityProvider(.sendVideo), videoTrack == nil {
            let videoSource = peerConnectionFactory.makeVideoSource(
                forScreenShare: false
            )

            if let oldCapturer = videoCapturer {
                Task { try await oldCapturer.stopCapture() }
            }

            let videoCapturer = VideoCapturer(
                videoSource: videoSource,
                videoOptions: videoOptions,
                videoFilters: videoConfig.videoFilters
            )
            let position: AVCaptureDevice.Position = callSettings.cameraPosition == .front
                ? .front
                : .back

            Task {
                do {
                    try await videoCapturer.startCapture(
                        device: videoCapturer.capturingDevice(for: position)
                    )
                } catch {
                    log.error(error)
                }
            }
            self.videoCapturer = videoCapturer
            videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
        }

        // TODO: Add support for screensharing
    }

    func makeScreenShareTrack(
        _ screenSharingType: ScreensharingType,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        videoConfig: VideoConfig
    ) {
        guard
            hasCapabilityProvider(.sendAudio),
            screenShareTrack == nil
        else {
            return
        }

        let videoSource = peerConnectionFactory.makeVideoSource(
            forScreenShare: true
        )

        if let oldCapturer = screenShareCapturer {
            Task { try await oldCapturer.stopCapture() }
        }

        let videoCapturer: VideoCapturing = {
            switch screenSharingType {
            case .inApp:
                return ScreenshareCapturer(
                    videoSource: videoSource,
                    videoOptions: videoOptions,
                    videoFilters: videoConfig.videoFilters
                )
            case .broadcast:
                return BroadcastScreenCapturer(
                    videoSource: videoSource,
                    videoOptions: videoOptions,
                    videoFilters: videoConfig.videoFilters
                )
            }
        }()

        screenShareCapturer = videoCapturer
        screenShareTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
    }
}
