//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import ReplayKit
import StreamWebRTC

final class BroadcastCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    private struct Session {
        var frameRate: Int = .defaultScreenShareFrameRate
        var adaptedOutputFormat: Bool = false
        var preferredDimensions: CGSize
        var videoSource: RTCVideoSource
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
    }

    private lazy var broadcastBufferReader = InjectedValues[\.broadcastBufferReader]
    private var activeSession: Session?

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles broadcast capture actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, dimensions, _, videoSource, videoCapturer, videoCapturerDelegate, _):
            try await execute(
                dimensions: dimensions,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
        case .stopCapture:
            broadcastBufferReader.stopCapturing()
            activeSession = nil
            log.debug("\(type(of: self)) stopped capturing.", subsystems: .videoCapturer)
        default:
            break
        }
    }

    // MARK: Private

    private func execute(
        dimensions: CGSize,
        videoSource: RTCVideoSource,
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) async throws {
        /// - Important: If a session is already active, we should not attempt to start a new one.
        /// The moment a new Connection is being created for a filePath that is already in use, then the
        /// current session stops and we end up in a state where we try to initiate the session, but we
        /// can't do it programmatically (user's interaction is required in order to present accept iOS popup).
        guard activeSession == nil else {
            return log.debug(
                "\(type(of: self)) unable to start broadcast as another session is active.",
                subsystems: .videoCapturer
            )
        }

        guard
            let identifier = infoPlistValue(for: BroadcastConstants.broadcastAppGroupIdentifier),
            let filePath = filePathForIdentifier(identifier)
        else {
            throw ClientError(
                "\(type(of: self)) unable to start broadcast as no shared container was found."
            )
        }

        InjectedValues[\.broadcastBufferReader] = .init()

        guard
            let socketConnection = BroadcastBufferReaderConnection(
                filePath: filePath,
                streamDelegate: broadcastBufferReader
            )
        else {
            throw ClientError(
                "\(type(of: self)) unable to start broadcast as socket connection couldn't be established."
            )
        }

        broadcastBufferReader.onCapture = { [weak self] pixelBuffer, rotation in
            self?.didReceive(
                pixelBuffer: pixelBuffer,
                rotation: rotation
            )
        }

        broadcastBufferReader.startCapturing(with: socketConnection)

        activeSession = .init(
            preferredDimensions: dimensions,
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate
        )

        log.debug(
            "\(type(of: self)) started capturing.",
            subsystems: .videoCapturer
        )
    }

    private func didReceive(
        pixelBuffer: CVPixelBuffer,
        rotation: RTCVideoRotation
    ) {
        guard
            let activeSession = self.activeSession
        else {
            log.warning(
                "\(type(of: self)) received sample buffer but no active session was found.",
                subsystems: .videoCapturer
            )
            return
        }

        let systemTime = ProcessInfo.processInfo.systemUptime
        let timeStampNs = Int64(systemTime * Double(NSEC_PER_SEC))

        let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let rtcFrame = RTCVideoFrame(
            buffer: rtcBuffer,
            rotation: rotation,
            timeStampNs: timeStampNs
        )

        activeSession.videoCapturerDelegate.capturer(
            activeSession.videoCapturer,
            didCapture: rtcFrame
        )

        adaptOutputFormatIfRequired(
            .init(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
        )
    }

    private func adaptOutputFormatIfRequired(
        _ bufferDimensions: CGSize
    ) {
        guard
            let activeSession,
            !activeSession.adaptedOutputFormat
        else { return }

        let adaptedDimensions = bufferDimensions.adjusted(
            toFit: max(
                activeSession.preferredDimensions.width,
                activeSession.preferredDimensions.height
            )
        )

        activeSession.videoSource.adaptOutputFormat(
            toWidth: Int32(adaptedDimensions.width),
            height: Int32(adaptedDimensions.height),
            fps: Int32(activeSession.frameRate)
        )

        self.activeSession?.adaptedOutputFormat = true

        log.debug(
            "\(type(of: self)) videoSource adaptation executed for dimensions:\(bufferDimensions).",
            subsystems: .videoCapturer
        )
    }

    private func filePathForIdentifier(_ identifier: String) -> String? {
        guard let sharedContainer = FileManager
            .default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)
        else {
            return nil
        }

        return sharedContainer
            .appendingPathComponent(BroadcastConstants.broadcastSharePath)
            .path
    }
}
