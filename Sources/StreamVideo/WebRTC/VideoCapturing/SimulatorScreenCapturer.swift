//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreGraphics
import Foundation
import StreamWebRTC

final class SimulatorScreenCapturer: RTCVideoCapturer, @unchecked Sendable {
    private var displayLink: CADisplayLink?
    private var videoURL: URL
    private let queue = DispatchQueue(label: "org.webrtc.RTCFileVideoCapturer")
    private var assetReader: AVAssetReader?
    private var videoTrackOutput: AVAssetReaderOutput?
    private var videoRotation: RTCVideoRotation = ._0
    // Cache the rotation after the first frame to avoid repeated detection.
    private var resolvedRotation: RTCVideoRotation?
    private var trackNaturalSize: CGSize = .zero
    private var trackDisplaySize: CGSize = .zero
    private let disposableBag = DisposableBag()

    init(delegate: RTCVideoCapturerDelegate, videoURL: URL) {
        self.videoURL = videoURL
        super.init(delegate: delegate)

        startCapturing()
    }

    deinit {
        log.debug("\(type(of: self)) deallocated.")
    }

    func startCapturing() {
        queue.async { [weak self] in
            guard let self else { return }
            self.setupAssetReader()
            self.displayLink = CADisplayLink(
                target: self,
                selector: #selector(self.readFrame)
            )
            self.displayLink?.preferredFramesPerSecond = 30 // Assuming 30 fps video
            self.displayLink?.add(to: .main, forMode: .common)
        }
    }

    func stopCapturing() {
        videoTrackOutput = nil
        displayLink?.invalidate()
        displayLink = nil
        assetReader?.cancelReading()
        assetReader = nil
    }

    private func setupAssetReader() {
        assetReader?.cancelReading()
        assetReader = nil
        videoTrackOutput = nil

        let asset = AVAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .video).first else { return }
        videoRotation = rotation(from: track.preferredTransform)
        trackNaturalSize = track.naturalSize
        trackDisplaySize = displaySize(for: track)
        resolvedRotation = nil

        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let trackOutput: AVAssetReaderOutput
        if let composition = videoComposition(for: asset, track: track) {
            let compositionOutput = AVAssetReaderVideoCompositionOutput(
                videoTracks: [track],
                videoSettings: outputSettings
            )
            compositionOutput.videoComposition = composition
            trackOutput = compositionOutput
            // Composition output already bakes rotation into pixels.
            videoRotation = ._0
            resolvedRotation = ._0
        } else {
            trackOutput = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: outputSettings
            )
        }
        do {
            assetReader = try AVAssetReader(asset: asset)
            assetReader?.add(trackOutput)
            videoTrackOutput = trackOutput
            assetReader?.startReading()
        } catch {
            print("Could not start reading asset: \(error)")
        }
    }

    @objc private func readFrame() {
        guard displayLink != nil, let trackOutput = videoTrackOutput else {
            return
        }

        if let sampleBuffer = trackOutput.copyNextSampleBuffer(), CMSampleBufferIsValid(sampleBuffer) {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let rotation = resolvedRotation ?? resolvedRotationForFirstFrame(pixelBuffer: pixelBuffer)
            if resolvedRotation == nil {
                resolvedRotation = rotation
            }
            let videoFrame = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let rtcVideoFrame = RTCVideoFrame(
                buffer: videoFrame,
                rotation: rotation,
                timeStampNs: Int64(CMTimeGetSeconds(frameTime) * 1e9)
            )

            Task(disposableBag: disposableBag) { @MainActor [weak self] in
                guard let self else {
                    return
                }
                delegate?.capturer(self, didCapture: rtcVideoFrame)
            }
        } else {
            // Reached the end of the video file, restart from the beginning
            setupAssetReader()
        }
    }

    private func resolvedRotationForFirstFrame(
        pixelBuffer: CVPixelBuffer
    ) -> RTCVideoRotation {
        let bufferSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        if isClose(bufferSize, trackDisplaySize) {
            // Buffer is already in display orientation; avoid double-rotation.
            return ._0
        }
        if isClose(bufferSize, trackNaturalSize) {
            // Buffer matches the track's natural size; apply preferred rotation.
            return videoRotation
        }
        // Fallback to a best-effort normalization.
        return normalizedRotationFallback(videoRotation, bufferSize: bufferSize)
    }

    private func normalizedRotationFallback(
        _ rotation: RTCVideoRotation,
        bufferSize: CGSize
    ) -> RTCVideoRotation {
        switch rotation {
        case ._90, ._270:
            if bufferSize.width < bufferSize.height {
                return ._0
            }
            return rotation
        default:
            return rotation
        }
    }

    private func displaySize(for track: AVAssetTrack) -> CGSize {
        let rect = CGRect(origin: .zero, size: track.naturalSize)
        let transformed = rect.applying(track.preferredTransform)
        return CGSize(
            width: abs(transformed.size.width),
            height: abs(transformed.size.height)
        )
    }

    private func isClose(_ lhs: CGSize, _ rhs: CGSize) -> Bool {
        let epsilon: CGFloat = 1.0
        return abs(lhs.width - rhs.width) <= epsilon &&
            abs(lhs.height - rhs.height) <= epsilon
    }

    private func videoComposition(
        for asset: AVAsset,
        track: AVAssetTrack
    ) -> AVMutableVideoComposition? {
        let composition = AVMutableVideoComposition()
        composition.renderSize = displaySize(for: track)

        let frameRate = track.nominalFrameRate
        let fps = frameRate > 0 ? frameRate : 30
        composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: asset.duration
        )

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        layerInstruction.setTransform(track.preferredTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]

        return composition
    }

    private func rotation(from transform: CGAffineTransform) -> RTCVideoRotation {
        let epsilon: CGFloat = 0.001
        func isClose(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
            abs(lhs - rhs) <= epsilon
        }

        let a = transform.a
        let b = transform.b
        let c = transform.c
        let d = transform.d

        if isClose(a, 0), isClose(b, 1), isClose(c, -1), isClose(d, 0) {
            return ._90
        }
        if isClose(a, 0), isClose(b, -1), isClose(c, 1), isClose(d, 0) {
            return ._270
        }
        if isClose(a, -1), isClose(b, 0), isClose(c, 0), isClose(d, -1) {
            return ._180
        }
        if isClose(a, 1), isClose(b, 0), isClose(c, 0), isClose(d, 1) {
            return ._0
        }
        return ._0
    }
}

/// Provides the default value of the `SimulatorStreamFile` class.
enum SimulatorStreamFileKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: URL?
}

extension InjectedValues {

    public var simulatorStreamFile: URL? {
        get {
            #if targetEnvironment(simulator)
            Self[SimulatorStreamFileKey.self]
            #else
            return nil
            #endif
        }
        set {
            #if targetEnvironment(simulator)
            Self[SimulatorStreamFileKey.self] = newValue
            #endif
        }
    }
}
