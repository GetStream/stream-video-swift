//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

#if os(iOS) && targetEnvironment(macCatalyst)

import AVFoundation
import CoreMedia
import Foundation
import ScreenCaptureKit
import StreamWebRTC

@available(macCatalyst 18.2, *)
final class ScreenShareCaptureHandlerMacOS: NSObject, StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: Nested Types

    private struct Session {
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
        var audioCapturer: RTCPCMAudioCapturer?
    }

    private struct ContentDescriptor {
        let filter: SCContentFilter
        let display: SCDisplay
        let info: SCShareableContentInfo?
    }

    // MARK: Properties

    @Atomic private var isCapturing = false
    private var activeSession: Session?

    private let audioConverter = ScreenShareAudioConverter()
    private let audioDiagnostics = ScreenShareAudioDiagnostics()
    private let disposableBag = DisposableBag()

    private lazy var streamOutput: ScreenShareStreamOutput = {
        let output = ScreenShareStreamOutput()
        output.delegate = self
        return output
    }()

    private let videoQueue = DispatchQueue(
        label: "io.getstream.StreamVideo.ScreenShareCaptureHandler.video"
    )
    private let audioQueue = DispatchQueue(
        label: "io.getstream.StreamVideo.ScreenShareCaptureHandler.audio"
    )

    private var stream: SCStream?
    private var contentDescriptor: ContentDescriptor?
    private var configuration: SCStreamConfiguration?

    // MARK: StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(
            _,
            dimensions,
            frameRate,
            _,
            videoCapturer,
            videoCapturerDelegate
        ):
            try await startCapture(
                dimensions: dimensions,
                frameRate: frameRate,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

        case .stopCapture:
            try await stopCapture()

        case let .startAudioCapture(capturer):
            activeSession?.audioCapturer = capturer

        case .stopAudioCapture:
            activeSession?.audioCapturer = nil

        default:
            break
        }
    }

    // MARK: Capture Lifecycle

    private func startCapture(
        dimensions: CGSize,
        frameRate: Int,
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) async throws {
        guard !isCapturing else {
            activeSession = Session(
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate,
                audioCapturer: activeSession?.audioCapturer
            )
            return
        }

        let descriptor = try await makeContentDescriptor()
        let configuration = makeStreamConfiguration(
            dimensions: dimensions,
            frameRate: frameRate,
            descriptor: descriptor
        )

        try await configureAndStartStream(
            with: descriptor,
            configuration: configuration
        )

        activeSession = Session(
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            audioCapturer: activeSession?.audioCapturer
        )

        contentDescriptor = descriptor
        self.configuration = configuration
        isCapturing = true

        log.debug(
            "\(type(of: self)) started capturing via ScreenCaptureKit.",
            subsystems: .videoCapturer
        )
    }

    private func stopCapture() async throws {
        guard isCapturing else {
            return
        }
        isCapturing = false

        let stream = stream
        let configuration = configuration

        self.stream = nil
        self.configuration = nil
        contentDescriptor = nil

        if let stream {
            do {
                if let configuration, configuration.capturesAudio {
                    try stream.removeStreamOutput(
                        streamOutput,
                        type: .audio
                    )
                }
                try stream.removeStreamOutput(streamOutput, type: .screen)
            } catch {
                log.error(error, subsystems: .videoCapturer)
            }

            do {
                try await stream.stopCapture()
            } catch {
                log.error(error, subsystems: .videoCapturer)
            }
        }

        activeSession = nil
    }

    // MARK: Stream Setup

    private func makeContentDescriptor() async throws -> ContentDescriptor {
        let shareableContent = try await SCShareableContent.current

        guard let display = shareableContent.displays.first else {
            throw ClientError("No displays available for screen capture.")
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let info = SCShareableContent.info(for: filter)

        return ContentDescriptor(
            filter: filter,
            display: display,
            info: info
        )
    }

    private func makeStreamConfiguration(
        dimensions: CGSize,
        frameRate: Int = 30,
        descriptor: ContentDescriptor
    ) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()

        let targetSize = targetPixelSize(
            descriptor: descriptor,
            requestedDimensions: dimensions
        )

        configuration.width = targetSize.width
        configuration.height = targetSize.height
        configuration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        configuration.showsCursor = true
        configuration.scalesToFit = false
        configuration.queueDepth = 4
        configuration.capturesAudio = true
        configuration.sampleRate = 48000
        configuration.channelCount = 2
        configuration.excludesCurrentProcessAudio = true
        configuration.captureResolution = .automatic
        configuration.includeChildWindows = true
        configuration.shouldBeOpaque = false

        if frameRate > 0 {
            configuration.minimumFrameInterval = CMTime(
                value: 1,
                timescale: CMTimeScale(frameRate)
            )
        } else {
            configuration.minimumFrameInterval = .zero
        }

        if descriptor.filter.style == .display {
            configuration.sourceRect = descriptor.info?.contentRect ?? descriptor.display.frame
        }

        if let colorSpaceName = CGColorSpace(name: CGColorSpace.sRGB)?.name {
            configuration.colorSpaceName = colorSpaceName
        }

        return configuration
    }

    private func targetPixelSize(
        descriptor: ContentDescriptor,
        requestedDimensions: CGSize
    ) -> (width: Int, height: Int) {
        let requestedWidth = Int(requestedDimensions.width.rounded())
        let requestedHeight = Int(requestedDimensions.height.rounded())

        if requestedWidth > 0, requestedHeight > 0 {
            return (requestedWidth, requestedHeight)
        }

        if let info = descriptor.info {
            let scale = CGFloat(info.pointPixelScale)
            let rect = info.contentRect
            let width = Int((rect.width * scale).rounded())
            let height = Int((rect.height * scale).rounded())
            return (
                max(width, Int(descriptor.display.width)),
                max(height, Int(descriptor.display.height))
            )
        }

        return (
            max(Int(descriptor.display.width), 1),
            max(Int(descriptor.display.height), 1)
        )
    }

    private func configureAndStartStream(
        with descriptor: ContentDescriptor,
        configuration: SCStreamConfiguration
    ) async throws {
        let stream = SCStream(
            filter: descriptor.filter,
            configuration: configuration,
            delegate: self
        )

        self.stream = stream

        do {
            try stream.addStreamOutput(
                streamOutput,
                type: .screen,
                sampleHandlerQueue: videoQueue
            )

            if configuration.capturesAudio {
                try stream.addStreamOutput(
                    streamOutput,
                    type: .audio,
                    sampleHandlerQueue: audioQueue
                )
            }

            try await stream.startCapture()
        } catch {
            self.stream = nil
            throw error
        }
    }
}

// MARK: - Sample Handling

@available(macCatalyst 18.2, *)
extension ScreenShareCaptureHandlerMacOS: ScreenShareStreamOutputDelegate {
    fileprivate func screenShareStreamOutput(
        _ output: ScreenShareStreamOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        type: SCStreamOutputType
    ) {
        switch type {
        case .screen:
            processVideoBuffer(sampleBuffer)
        case .audio:
            processAudioBuffer(sampleBuffer)
        case .microphone:
            break
        @unknown default:
            break
        }
    }

    private func processVideoBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard
            let activeSession,
            shouldProcessVideoSample(sampleBuffer),
            CMSampleBufferIsValid(sampleBuffer),
            CMSampleBufferDataIsReady(sampleBuffer),
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timeStampNs = Int64(
            CMTimeGetSeconds(timestamp) * Double(NSEC_PER_SEC)
        )

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

    private func shouldProcessVideoSample(
        _ sampleBuffer: CMSampleBuffer
    ) -> Bool {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer,
                createIfNecessary: false
            ) as? [[AnyHashable: Any]],
            let attachment = attachments.first,
            let statusNumber = attachment[SCStreamFrameInfo.status as AnyHashable] as? NSNumber,
            let status = SCFrameStatus(rawValue: statusNumber.intValue)
        else {
            return true
        }

        switch status {
        case .complete, .started:
            return true
        default:
            return false
        }
    }

    private func processAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let audioCapturer = activeSession?.audioCapturer else {
            return
        }

        switch audioConverter.convert(sampleBuffer) {
        case let .success(buffer):
            audioDiagnostics.analyze(
                original: sampleBuffer,
                converted: buffer
            )
            audioCapturer.capture(buffer)

        case .empty:
            log.info(
                "\(type(of: self)) screen share audio buffer empty.",
                subsystems: .videoCapturer
            )

        case let .noData(streamDescription, status, inputFrames):
            let message =
                "\(type(of: self)) audio conversion no data "
                    + "(status:\(status.rawValue) inputFrames:\(inputFrames) "
                    + "sampleRate:\(streamDescription.mSampleRate) "
                    + "channels:\(streamDescription.mChannelsPerFrame))."

            log.warning(
                message,
                subsystems: .videoCapturer
            )

        case let .failure(file, function, line):
            log.error(
                "\(type(of: self)) audio conversion failed.",
                subsystems: .videoCapturer,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
        }
    }
}

// MARK: - SCStreamDelegate

@available(macCatalyst 18.2, *)
extension ScreenShareCaptureHandlerMacOS: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        log.error(error, subsystems: .videoCapturer)
        Task(disposableBag: disposableBag) { [weak self] in
            do {
                try await self?.stopCapture()
            } catch {
                log.error(error, subsystems: .videoCapturer)
            }
        }
    }
}

// MARK: - Helpers

@available(macCatalyst 18.2, *)
private protocol ScreenShareStreamOutputDelegate: AnyObject {
    func screenShareStreamOutput(
        _ output: ScreenShareStreamOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        type: SCStreamOutputType
    )
}

@available(macCatalyst 18.2, *)
private final class ScreenShareStreamOutput: NSObject, SCStreamOutput {
    weak var delegate: ScreenShareStreamOutputDelegate?

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        delegate?.screenShareStreamOutput(
            self,
            didOutput: sampleBuffer,
            type: type
        )
    }
}

#endif
