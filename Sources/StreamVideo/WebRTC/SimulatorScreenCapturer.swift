//
//  SimulatorScreenCapturer.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 2/11/23.
//

import Foundation
import WebRTC

final class SimulatorScreenCapturer: RTCVideoCapturer {
    private var displayLink: CADisplayLink?
    private var videoURL: URL
    private let queue = DispatchQueue(label: "org.webrtc.RTCFileVideoCapturer")
    private var assetReader: AVAssetReader?
    private var videoTrackOutput: AVAssetReaderTrackOutput?

    init(delegate: RTCVideoCapturerDelegate, videoURL: URL) {
        self.videoURL = videoURL
        super.init(delegate: delegate)

        startCapturing()
    }

    func startCapturing() {
        queue.async {
            self.setupAssetReader()
            self.displayLink = CADisplayLink(target: self, selector: #selector(self.readFrame))
            self.displayLink?.preferredFramesPerSecond = 30 // Assuming 30 fps video
            self.displayLink?.add(to: .current, forMode: .common)
            RunLoop.current.run()
        }
    }

    func stopCapturing() {
        displayLink?.invalidate()
        assetReader?.cancelReading()
    }

    private func setupAssetReader() {
        let asset = AVAsset(url: videoURL)
        guard let track = asset.tracks(withMediaType: .video).first else { return }

        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)])
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
        guard let trackOutput = videoTrackOutput else {
            return
        }

        if let sampleBuffer = trackOutput.copyNextSampleBuffer(), CMSampleBufferIsValid(sampleBuffer) {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let videoFrame = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let rtcVideoFrame = RTCVideoFrame(buffer: videoFrame, rotation: ._0, timeStampNs: Int64(CMTimeGetSeconds(frameTime) * 1e9))

            DispatchQueue.main.async {
                self.delegate?.capturer(self, didCapture: rtcVideoFrame)
            }
        } else {
            // Reached the end of the video file, restart from the beginning
            self.assetReader?.cancelReading()
            self.setupAssetReader()
        }
    }
}

/// Provides the default value of the `SimulatorStreamFile` class.
public struct SimulatorStreamFileKey: InjectionKey {
    public static var currentValue: URL? = nil
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
