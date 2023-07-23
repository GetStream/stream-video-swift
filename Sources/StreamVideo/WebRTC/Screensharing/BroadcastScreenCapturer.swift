//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
#if canImport(ReplayKit)
import ReplayKit
#endif

class BroadcastScreenCapturer: VideoCapturing {
    
    var frameReader: SocketConnectionFrameReader?
    
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
        let width = bounds.size.width
        let height = bounds.size.height

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
            self.videoSource.adaptOutputFormat(
                toWidth: Int32(width),
                height: Int32(height),
                fps: Int32(30)
            )
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
