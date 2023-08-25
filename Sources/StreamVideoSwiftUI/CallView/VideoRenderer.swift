//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI
import WebRTC
import MetalKit

public struct LocalVideoView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    private let callSettings: CallSettings
    private var viewFactory: Factory
    private var participant: CallParticipant
    private var idSuffix: String
    private var call: Call?
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        idSuffix: String = "local",
        callSettings: CallSettings,
        call: Call?
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.idSuffix = idSuffix
        self.callSettings = callSettings
        self.call = call
    }
            
    public var body: some View {
        GeometryReader { reader in
            viewFactory.makeVideoParticipantView(
                participant: participant,
                id: "\(streamVideo.user.id)-\(idSuffix)",
                availableSize: reader.size,
                contentMode: .scaleAspectFill,
                customData: ["videoOn": .bool(callSettings.videoOn)],
                call: call
            )
            .rotation3DEffect(
                .degrees(shouldRotate ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
    }
    
    private var shouldRotate: Bool {
        callSettings.cameraPosition == .front && callSettings.videoOn
    }
    
}

public struct VideoRendererView: UIViewRepresentable {
            
    public typealias UIViewType = VideoRenderer
    
    @Injected(\.utils) var utils
    
    var id: String
    var size: CGSize
    var contentMode: UIView.ContentMode
    var handleRendering: (VideoRenderer) -> Void
    var feedFrames: ((CMSampleBuffer) -> ())?
    
    public init(
        id: String,
        size: CGSize,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        handleRendering: @escaping (VideoRenderer) -> Void,
        feedFrames: ((CMSampleBuffer) -> ())? = nil
    ) {
        self.id = id
        self.size = size
        self.handleRendering = handleRendering
        self.contentMode = contentMode
        self.feedFrames = feedFrames
    }

    public func makeUIView(context: Context) -> VideoRenderer {
        let view = utils.videoRendererFactory.view(for: id, size: size)
        view.videoContentMode = contentMode
        view.backgroundColor = UIColor.black
        view.feedFrames = feedFrames
        handleRendering(view)
        return view
    }
    
    public func updateUIView(_ uiView: VideoRenderer, context: Context) {
        uiView.feedFrames = feedFrames
        handleRendering(uiView)
    }
}

public class VideoRenderer: RTCMTLVideoView {
    
    let queue = DispatchQueue(label: "video-track")
    
    weak var track: RTCVideoTrack?
    
    var feedFrames: ((CMSampleBuffer) -> ())?
    
    public func add(track: RTCVideoTrack) {
        queue.sync {
            if track.trackId == self.track?.trackId && track.readyState == .live {
                return
            }
            let view = subviews.compactMap { $0 as? MTKView }.first
            view?.preferredFramesPerSecond = 60
            self.track?.remove(self)
            self.track = nil
            log.debug("Adding track to the view")
            self.track = track
            track.add(self)
        }
    }
    
    public override func renderFrame(_ frame: RTCVideoFrame?) {
        super.renderFrame(frame)
        
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            if let feedFrames {
                guard let frame = frame else {
                    return
                }
                
                if let pixelBuffer = frame.buffer as? RTCCVPixelBuffer {
                    guard let sampleBuffer = CMSampleBuffer.from(pixelBuffer.pixelBuffer) else {
                        log.warning("Failed to convert CVPixelBuffer to CMSampleBuffer")
                        return
                    }

                    DispatchQueue.main.async {
                        feedFrames(sampleBuffer)
                    }
                } else if let i420buffer = frame.buffer as? RTCI420Buffer {
                    guard let image = i420buffer.toCGImage() else {
                        return
                    }
                    let ciImage = CIImage(cgImage: image)
                    guard let pixelBuffer = buffer(from: ciImage),
                            let sampleBuffer = CMSampleBuffer.from(pixelBuffer) else {
                        log.warning("Failed to convert CVPixelBuffer to CMSampleBuffer")
                        return
                    }

                    DispatchQueue.main.async {
                        feedFrames(sampleBuffer)
                    }
                }
            }
        }
        
        
    }
    
    deinit {
        log.debug("Deinit of video view")
        track?.remove(self)
    }
}

extension VideoRenderer {
    
    public func handleViewRendering(
        for participant: CallParticipant,
        onTrackSizeUpdate: @escaping (CGSize, CallParticipant) -> ()
    ) {
        if let track = participant.track {
            log.debug("adding track to a view \(self)")
            self.add(track: track)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let prev = participant.trackSize
                let scale = UIScreen.main.scale
                let newSize = CGSize(
                    width: self.bounds.size.width * scale,
                    height: self.bounds.size.height * scale
                )
                if prev != newSize {
                    onTrackSizeUpdate(newSize, participant)
                }
            }
        }
    }
    
}

//TODO: remove this.
extension CMSampleBuffer {

    static func from(_ pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
            var sampleBuffer: CMSampleBuffer?

            var timimgInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
            var formatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )

            _ = CMSampleBufferCreateReadyWithImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescription: formatDescription!,
                sampleTiming: &timimgInfo,
                sampleBufferOut: &sampleBuffer
            )

            return sampleBuffer
    }
}

func buffer(from image: CIImage) -> CVPixelBuffer? {

        let attrs = [kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

        var pixelBuffer : CVPixelBuffer?

        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.extent.width), Int(image.extent.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)



        guard (status == kCVReturnSuccess) else {

            return nil

        }

        return pixelBuffer

    }

import UIKit
import WebRTC

extension RTCI420Buffer {
    func toCGImage() -> CGImage? {
        let width = Int(self.width)
        let height = Int(self.height)
        let yData = self.dataY
        let uData = self.dataU
        let vData = self.dataV

        // Create a CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, nil, &pixelBuffer)

        if status != kCVReturnSuccess {
            print("Error creating pixel buffer")
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
        let uPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)
        let vPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 2)

        let yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer!, 0)
        let uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer!, 1)
        let yLength = yBytesPerRow * height
        let uvLength = uvBytesPerRow * height / 2
        
        if let yPlane {
            let yDataConverted = Data(bytes: yData, count: Int(yLength))
            yDataConverted.copyBytes(to: yPlane.assumingMemoryBound(to: UInt8.self), count: Int(yLength))
        }
        if let uPlane {
            let uDataConverted = Data(bytes: uData, count: Int(uvLength))
            uDataConverted.copyBytes(to: uPlane.assumingMemoryBound(to: UInt8.self), count: Int(uvLength))
        }
        if let vPlane {
            let vDataConverted = Data(bytes: vData, count: Int(uvLength))
            vDataConverted.copyBytes(to: vPlane.assumingMemoryBound(to: UInt8.self), count: Int(uvLength))
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        // Create a CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer!)

        // Convert CIImage to UIImage
//        let context = CIContext(options: nil)
        let context = CIContext()

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return cgImage
        }

        return nil
    }
}

func clamp(value: Int16) -> UInt8 {
    return UInt8(min(max(value, 0), 255))
}

import CoreMedia
import CoreVideo

extension RTCI420Buffer {
    func toCMSampleBuffer() -> CMSampleBuffer? {
        let width = Int(self.width)
        let height = Int(self.height)
        let yData = self.dataY
        let uData = self.dataU
        let vData = self.dataV

        // Create a CVPixelBuffer
        var pixelBuffer: CVPixelBuffer?
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]

        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, pixelBufferAttributes as CFDictionary, &pixelBuffer)

        if status != kCVReturnSuccess {
            print("Error creating pixel buffer")
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 0)
        let uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer!, 1)

        let yBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer!, 0)
        let uvBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer!, 1)
        let yLength = yBytesPerRow * height
        let uvLength = uvBytesPerRow * height / 2

        yData.withMemoryRebound(to: UInt8.self, capacity: Int(yLength)) { srcY in
            let destY = yPlane?.assumingMemoryBound(to: UInt8.self)
            memcpy(destY, srcY, Int(yLength))
        }

        uData.withMemoryRebound(to: UInt8.self, capacity: Int(uvLength)) { srcU in
            let destU = uvPlane?.assumingMemoryBound(to: UInt8.self)
            memcpy(destU, srcU, Int(uvLength))
        }

        vData.withMemoryRebound(to: UInt8.self, capacity: Int(uvLength)) { srcV in
            let destV = uvPlane?.advanced(by: Int(uvLength)).assumingMemoryBound(to: UInt8.self)
            memcpy(destV, srcV, Int(uvLength))
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        // Create a CMSampleBuffer
        var sampleBuffer: CMSampleBuffer?
        var formatDescription: CMFormatDescription?

        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &formatDescription)

        var sampleTimingInfo = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: CMTime.zero, decodeTimeStamp: CMTime.invalid)

        let sampleSizeArray = [yLength + uvLength]
        let blockBufferLength = yLength + uvLength
        var blockBuffer: CMBlockBuffer?
        CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: blockBufferLength, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: blockBufferLength, flags: kCMBlockBufferAlwaysCopyDataFlag, blockBufferOut: &blockBuffer)
        CMBlockBufferReplaceDataBytes(with: yData, blockBuffer: blockBuffer!, offsetIntoDestination: 0, dataLength: yLength)
        CMBlockBufferReplaceDataBytes(with: uData, blockBuffer: blockBuffer!, offsetIntoDestination: yLength, dataLength: uvLength)

        CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer!,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription!,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &sampleTimingInfo,
            sampleSizeEntryCount: 1,
            sampleSizeArray: sampleSizeArray,
            sampleBufferOut: &sampleBuffer
        )

        return sampleBuffer
    }
}
