//
//  LocalScreenShareMediaAdapter.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 6/8/24.
//

import Foundation
import Combine
import StreamWebRTC

final class LocalScreenShareMediaAdapter: LocalMediaAdapting, @unchecked Sendable {

    private let sessionID: String
    private let peerConnection: RTCPeerConnection
    private let peerConnectionFactory: PeerConnectionFactory
    private var sfuAdapter: SFUAdapter
    private let videoOptions: VideoOptions
    private let videoConfig: VideoConfig

    private let queue = UnfairQueue()

    private(set) var localTrack: RTCVideoTrack?
    private var activeTask: Task<Void, Never>?
    private var screenSharingType: ScreensharingType? = nil
    private var capturer: VideoCapturing?
    private var sender: RTCRtpTransceiver?

    var mid: String? { sender?.mid }

    let subject: PassthroughSubject<TrackEvent, Never>
    var isPublishing: Bool { queue.sync { sender != nil && localTrack?.isEnabled == true } }

    init(
        sessionID: String,
        peerConnection: RTCPeerConnection,
        peerConnectionFactory: PeerConnectionFactory,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions,
        videoConfig: VideoConfig,
        subject: PassthroughSubject<TrackEvent, Never>
    ) {
        self.sessionID = sessionID
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.sfuAdapter = sfuAdapter
        self.videoOptions = videoOptions
        self.videoConfig = videoConfig
        self.subject = subject
    }

    deinit {
        Task { [capturer] in try? await capturer?.stopCapture() }
        localTrack?.isEnabled = false
        sender?.stopInternal()
    }

    // MARK: - LocalMediaManaging

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        /* No-op */
    }

    func publish() {
        guard
            let localTrack
        else {
            return
        }

        activeTask?.cancel()
        activeTask = Task {
            do {
                try await sfuAdapter.updateTrackMuteState(
                    .screenShare,
                    isMuted:false,
                    for: sessionID
                )

                try Task.checkCancellation()
                
                queue.sync {
                    if sender == nil, let screenSharingType  {
                        self.sender = peerConnection.addTransceiver(
                            with: localTrack,
                            init: RTCRtpTransceiverInit(
                                trackType: .screenshare,
                                direction: .sendOnly,
                                streamIds: ["\(sessionID)-screenshare-\(screenSharingType)"],
                                codecs: videoOptions.supportedCodecs
                            )
                        )
                        localTrack.isEnabled = true
                    } else {
                        sender?.sender.track = localTrack
                        localTrack.isEnabled = true
                    }
                }
                log.debug("Local screenShareTrack trackId:\(localTrack.trackId) is now published.")
            } catch {
                log.error(error)
            }
        }
    }

    func unpublish() {
        activeTask?.cancel()
        activeTask = Task {
            do {
                try await capturer?.stopCapture()

                try Task.checkCancellation()
                
                queue.sync {
                    guard
                        let localTrack,
                        localTrack.isEnabled
                    else {
                        log.debug("VideoTrack is not published to unpublish.")
                        return
                    }
                    localTrack.isEnabled = false
                    sender?.sender.track = nil
                    log.debug("Local screenShareTrack trackId:\(localTrack.trackId) is now unpublished.")
                }
            } catch {
                log.error(error)
            }
        }
    }

    func didUpdateCallSettings(
        _ settings: CallSettings
    ) async throws {
        /* No-op */
    }

    // MARK: - Screensharing

    func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability],
        removeAllScreenSharingStreams: @escaping () -> Void
    ) async throws {
        let hasScreenShare = ownCapabilities.contains(.screenshare)

        if hasScreenShare, localTrack == nil {
            try await makeVideoTrack(type)
            publish()

        } else if hasScreenShare, type != screenSharingType {
            sender?.stopInternal()
            removeAllScreenSharingStreams()
            try await makeVideoTrack(type)
            publish()

        } else if
            hasScreenShare,
            type == screenSharingType,
            localTrack != nil,
            sender != nil
        {
            publish()

        } else if !hasScreenShare {
            queue.sync {
                localTrack = nil
                screenSharingType = nil
                sender?.stopInternal()
                Task {
                    do {
                        try await capturer?.stopCapture()
                    } catch {
                        log.error(error)
                    }
                }
            }
            throw ClientError.MissingPermissions()
        }
    }

    func stopScreenSharing() {
        unpublish()
    }

    // MARK: - Private helpers

    private func makeVideoTrack(
        _ screenSharingType: ScreensharingType
    ) async throws {
        let videoSource = peerConnectionFactory
            .makeVideoSource(forScreenShare: true)
        let videoTrack = peerConnectionFactory.makeVideoTrack(source: videoSource)
        queue.sync {
            sender?.stopInternal()
            sender = nil
            localTrack = videoTrack
            self.screenSharingType = screenSharingType
        }
        subject.send(
            .added(
                id: sessionID,
                trackType: .screenshare,
                track: videoTrack
            )
        )

        try await capturer?.stopCapture()
        switch screenSharingType {
        case .inApp:
            capturer = ScreenshareCapturer(
                videoSource: videoSource,
                videoOptions: videoOptions,
                videoFilters: videoConfig.videoFilters
            )
        case .broadcast:
            capturer = BroadcastScreenCapturer(
                videoSource: videoSource,
                videoOptions: videoOptions,
                videoFilters: videoConfig.videoFilters
            )
        }
    }
}

extension RTCVideoTrack: @unchecked Sendable {}
