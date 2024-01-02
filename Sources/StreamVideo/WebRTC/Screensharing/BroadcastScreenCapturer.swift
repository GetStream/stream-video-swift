//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import ReplayKit

class BroadcastScreenCapturer: VideoCapturing {
    
    var bufferReader: BroadcastBufferReader?
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
        guard self.bufferReader == nil else {
            return
        }
        
        guard let identifier = infoPlistValue(for: BroadcastConstants.broadcastAppGroupIdentifier),
              let filePath = self.filePathForIdentifier(identifier)
        else {
            return
        }
        
        let bufferReader = BroadcastBufferReader()
        
        guard let socketConnection = BroadcastBufferReaderConnection(
            filePath: filePath,
            streamDelegate: bufferReader
        ) else {
            return
        }
        
        bufferReader.onCapture = { [weak self] pixelBuffer, rotation in
            guard let self else { return }
            let systemTime = ProcessInfo.processInfo.systemUptime
            let timeStampNs = Int64(systemTime * Double(NSEC_PER_SEC))
            
            let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            let rtcFrame = RTCVideoFrame(
                buffer: rtcBuffer,
                rotation: rotation,
                timeStampNs: timeStampNs
            )
            
            var bufferDimensions = (
                width: Int32(CVPixelBufferGetWidth(pixelBuffer)),
                height: Int32(CVPixelBufferGetHeight(pixelBuffer))
            )
            
            bufferDimensions = BroadcastUtils.adjust(
                width: bufferDimensions.width,
                height: bufferDimensions.height,
                size: max(
                    self.videoOptions.preferredDimensions.width,
                    self.videoOptions.preferredDimensions.height
                )
            )
            
            self.videoCaptureHandler?.capturer(self.videoCapturer, didCapture: rtcFrame)
            if !self.adaptedOutputFormat {
                self.adaptedOutputFormat = true
                self.videoSource.adaptOutputFormat(
                    toWidth: bufferDimensions.width,
                    height: bufferDimensions.height,
                    fps: 15
                )
            }
        }
        bufferReader.startCapturing(with: socketConnection)
        self.bufferReader = bufferReader
    }
    
    func stopCapture() async throws {
        guard self.bufferReader != nil else {
            // already stopped
            return
        }
        
        self.bufferReader?.stopCapturing()
        self.bufferReader = nil
        await (videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
    }
    
    private func filePathForIdentifier(_ identifier: String) -> String? {
        guard let sharedContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: identifier
        ) else {
            return nil
        }
        
        let filePath = sharedContainer.appendingPathComponent(
            BroadcastConstants.broadcastSharePath
        ).path
        
        return filePath
    }
}
