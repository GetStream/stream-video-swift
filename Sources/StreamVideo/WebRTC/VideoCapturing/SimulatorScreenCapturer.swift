//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class SimulatorScreenCapturer: RTCVideoCapturer, @unchecked Sendable {
    private var displayLink: CADisplayLink?
    private var videoURL: URL
    private let queue = DispatchQueue(label: "org.webrtc.RTCFileVideoCapturer")
    private var assetReader: AVAssetReader?
    private var videoTrackOutput: AVAssetReaderTrackOutput?
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

        let trackOutput = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
        )
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
            let videoFrame = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let rtcVideoFrame = RTCVideoFrame(
                buffer: videoFrame,
                rotation: ._0,
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
