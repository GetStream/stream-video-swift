//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
import ReplayKit

class BroadcastScreenCapturer: VideoCapturing {
    
    var frameReader: SocketConnectionFrameReader?
    var adaptedOutputFormat = false
    
    private var videoCapturer: RTCVideoCapturer
    private var videoOptions: VideoOptions
    private let videoSource: RTCVideoSource
    private var videoCaptureHandler: StreamVideoCaptureHandler?
    
    init(
        videoSource: RTCVideoSource,
        videoOptions: VideoOptions,
        videoFilters: [VideoFilter]
    ) {
        self.videoOptions = videoOptions
        self.videoSource = videoSource
#if targetEnvironment(simulator)
        videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
#else
        let handler = StreamVideoCaptureHandler(source: videoSource, filters: videoFilters, handleRotation: false)
        videoCaptureHandler = handler
        videoCapturer = RTCCameraVideoCapturer(delegate: handler)
#endif
    }
    
    func startCapture(device: AVCaptureDevice?) async throws {
        guard self.frameReader == nil else {
            // already started
            return
        }
        
        guard let identifier = self.lookUpAppGroupIdentifier(),
              let filePath = self.filePathForIdentifier(identifier)
        else {
            return
        }
        
        let bounds = await UIScreen.main.bounds
        let width = Int32(bounds.size.width)
        let height = Int32(bounds.size.height)
        
        var targetDimensions = aspectFit(
            width: width,
            height: height,
            size: Swift.max(videoOptions.preferredDimensions.width, videoOptions.preferredDimensions.height)
        )
        targetDimensions = toEncodeSafeDimensions(width: targetDimensions.width, height: targetDimensions.height)
        
        let frameReader = SocketConnectionFrameReader()
        guard let socketConnection = BroadcastServerSocketConnection(filePath: filePath, streamDelegate: frameReader)
        else {
            return
        }
        frameReader.didCapture = { [weak self] pixelBuffer, rotation in
            guard let self else { return }
            let systemTime = ProcessInfo.processInfo.systemUptime
            let timeStampNs = Int64(systemTime * Double(NSEC_PER_SEC))
            
            let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let rtcFrame = RTCVideoFrame(
                buffer: rtcBuffer,
                rotation: rotation,
                timeStampNs: timeStampNs
            )
            
            self.videoCaptureHandler?.capturer(self.videoCapturer, didCapture: rtcFrame)
            if !adaptedOutputFormat {
                adaptedOutputFormat = true
                self.videoSource.adaptOutputFormat(
                    toWidth: targetDimensions.width,
                    height: targetDimensions.height,
                    fps: 15
                )
            }
        }
        frameReader.startCapture(with: socketConnection)
        self.frameReader = frameReader
    }
    
    func stopCapture() async throws {
        guard self.frameReader != nil else {
            // already stopped
            return
        }
        
        self.frameReader?.stopCapture()
        self.frameReader = nil
        await (videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
    }
    
    func toEncodeSafeDimensions(width: Int32, height: Int32) -> (width: Int32, height: Int32) {
        (
            width: Swift.max(16, width.roundUp(toMultipleOf: 2)),
            height: Swift.max(16, height.roundUp(toMultipleOf: 2))
        )
    }
    
    func aspectFit(width: Int32, height: Int32, size: Int32) -> (width: Int32, height: Int32) {
        let c = width >= height
        let r = c ? Double(height) / Double(width) : Double(width) / Double(height)
        return (
            width: c ? size : Int32(r * Double(size)),
            height: c ? Int32(r * Double(size)) : size
        )
    }
    
    private func lookUpAppGroupIdentifier() -> String? {
        return Bundle.main.infoDictionary?["RTCAppGroupIdentifier"] as? String
    }
    
    private func filePathForIdentifier(_ identifier: String) -> String? {
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        else {
            return nil
        }
        
        let filePath = sharedContainer.appendingPathComponent("rtc_SSFD").path
        return filePath
    }
}
