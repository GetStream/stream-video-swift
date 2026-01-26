//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFoundation
import Foundation
import ReplayKit
import StreamWebRTC

/// Handles ReplayKit screen capture and forwards frames to WebRTC.
final class ScreenShareCaptureHandler: NSObject, StreamVideoCapturerActionHandler, RPScreenRecorderDelegate, @unchecked Sendable {

    @Injected(\.audioFilterProcessingModule) private var audioFilterProcessingModule

    @Atomic private var isRecording: Bool = false
    private var activeSession: Session?
    private let recorder: RPScreenRecorder
    private let includeAudio: Bool
    private let disposableBag = DisposableBag()
    private let audioProcessingQueue = DispatchQueue(
        label: "io.getstream.screenshare.audio.processing",
        qos: .userInitiated
    )
    private var audioFilterBeforeScreensharingAudio: AudioFilter?

    private struct Session {
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
        var audioDeviceModule: AudioDeviceModule
    }

    /// Creates a screen share capture handler.
    /// - Parameters:
    ///   - recorder: The ReplayKit recorder to use. Defaults to `.shared()`.
    ///   - includeAudio: Whether to capture app audio during screen sharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    init(recorder: RPScreenRecorder = .shared(), includeAudio: Bool) {
        self.recorder = recorder
        self.includeAudio = includeAudio
        super.init()
        recorder.delegate = self
    }

    // MARK: - RPScreenRecorderDelegate

    /// Logs availability changes for the ReplayKit screen recorder.
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        log.debug(
            "\(type(of: self)) availability changed to isAvailable:\(screenRecorder.isAvailable).",
            subsystems: .videoCapturer
        )
    }

    /// Handles ReplayKit stop events and tears down capture on error.
    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    ) {
        if let error {
            log.error(error, subsystems: .videoCapturer)
            Task(disposableBag: disposableBag) { [weak self] in
                do {
                    try await self?.stop()
                } catch {
                    log.error(error, subsystems: .videoCapturer)
                }
            }
        }
    }

    // MARK: - StreamVideoCapturerActionHandler

    /// Executes a capture action for screen sharing.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(
            _,
            _,
            _,
            _,
            videoCapturer,
            videoCapturerDelegate,
            audioDeviceModule
        ):
            try await execute(
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate,
                audioDeviceModule: audioDeviceModule
            )
        case .stopCapture:
            try await stop()
        default:
            break
        }
    }

    // MARK: Private

    /// Starts screen capture and wires the active capture session.
    private func execute(
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate,
        audioDeviceModule: AudioDeviceModule
    ) async throws {

        guard recorder.isAvailable else {
            throw ClientError("\(type(of: self)) isn't available for recording.")
        }

        guard !isRecording else {
            return
        }

        // We disable the microphone as we don't support .screenShareAudio tracks
        recorder.isMicrophoneEnabled = false
        recorder.isCameraEnabled = false

        audioFilterBeforeScreensharingAudio = audioFilterProcessingModule.activeAudioFilter
        audioFilterProcessingModule.setAudioFilter(nil)

        try await Task { @MainActor [weak self] in
            try await self?.startCapture { [weak self] sampleBuffer,
                sampleBufferType,
                error in
                if let error {
                    log.error(error, subsystems: .videoCapturer)
                } else {
                    self?.didReceive(
                        sampleBuffer: sampleBuffer,
                        sampleBufferType: sampleBufferType
                    )
                }
            }
        }.value

        activeSession = .init(
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            audioDeviceModule: audioDeviceModule
        )

        isRecording = true

        log.debug(
            "\(type(of: self)) started capturing.",
            subsystems: .videoCapturer
        )
    }

    /// Routes incoming sample buffers to video or audio processing.
    private func didReceive(
        sampleBuffer: CMSampleBuffer,
        sampleBufferType: RPSampleBufferType
    ) {
        switch sampleBufferType {
        case .video:
            processVideoBuffer(sampleBuffer: sampleBuffer)

        case .audioMic:
            log.warning(
                "\(type(of: self)) only video and appAudio sample buffers are supported. Received \(sampleBufferType).",
                subsystems: .videoCapturer
            )

        case .audioApp:
            if includeAudio {
                processAudioAppBuffer(sampleBuffer: sampleBuffer)
            } else {
                // We don't process any audio buffers for this session.
            }

        @unknown default:
            log.warning(
                "\(type(of: self)) received unknown sample buffer type: \(sampleBufferType).",
                subsystems: .videoCapturer
            )
        }
    }

    /// Converts a video sample buffer into a WebRTC video frame.
    private func processVideoBuffer(
        sampleBuffer: CMSampleBuffer
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

        guard
            CMSampleBufferGetNumSamples(sampleBuffer) == 1,
            CMSampleBufferIsValid(sampleBuffer),
            CMSampleBufferDataIsReady(sampleBuffer)
        else {
            log.debug(
                "\(type(of: self)) screenshare video sample buffer is invalid or not ready.",
                subsystems: .videoCapturer
            )
            return
        }

        guard
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            log.debug(
                "\(type(of: self)) unable to extract pixel buffer from sample buffer.",
                subsystems: .videoCapturer
            )
            return
        }

        let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timeStampNs = Int64(CMTimeGetSeconds(timeStamp) * Double(NSEC_PER_SEC))

        let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let rtcFrame = RTCVideoFrame(
            buffer: rtcBuffer,
            rotation: ._0,
            timeStampNs: timeStampNs
        )

        activeSession.videoCapturerDelegate.capturer(
            activeSession.videoCapturer,
            didCapture: rtcFrame
        )
    }

    /// Enqueues app audio buffers into the audio device module.
    private func processAudioAppBuffer(
        sampleBuffer: CMSampleBuffer
    ) {
        guard
            let audioDeviceModule = activeSession?.audioDeviceModule,
            isRecording
        else {
            log.warning(
                "\(type(of: self)) received sample buffer but no active session was found.",
                subsystems: .videoCapturer
            )
            return
        }

        audioDeviceModule.enqueue(sampleBuffer)
    }

    /// Stops ReplayKit capture and restores audio filters.
    private func stop() async throws {
        guard
            isRecording == true
        else {
            return
        }

        // Restore the previously disabled filter
        audioFilterProcessingModule.setAudioFilter(audioFilterBeforeScreensharingAudio)
        audioFilterBeforeScreensharingAudio = nil

        try await recorder.stopCapture()
        activeSession = nil
        isRecording = false
    }

    @MainActor
    /// Starts ReplayKit capture and binds the sample buffer handler.
    private func startCapture(
        _ closure: @Sendable @escaping (CMSampleBuffer, RPSampleBufferType, Error?) -> Void
    ) async throws {
        try await recorder.startCapture(handler: closure)
    }
}

extension RPScreenRecorder {

    /// Bridges the closure-based stop capture API to async/await.
    fileprivate func stopCapture() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: ClientError())
                return
            }
            self.stopCapture { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        } as Void
    }
}
