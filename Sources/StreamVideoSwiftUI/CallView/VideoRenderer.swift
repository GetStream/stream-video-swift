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
                guard let image = convertWebRTCFrame(frame: frame), let cgImage = image.cgImage else {
                    return
                }
                let ciImage = CIImage(cgImage: cgImage)
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

func convertWebRTCFrame(frame: RTCVideoFrame) -> UIImage? {
    guard let buffer = frame.buffer as? RTCI420Buffer else {
        return nil
    }
    
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    let bytesPerPixel = 4
    guard let rgbBuffer = malloc(width * height * bytesPerPixel) else {
        return nil
    }
    defer {
        free(rgbBuffer)
    }
    
    for row in 0..<height {
        let yLine = buffer.dataY.advanced(by: row * Int(buffer.strideY))
        let uLine = buffer.dataU.advanced(by: (row >> 1) * Int(buffer.strideU))
        let vLine = buffer.dataV.advanced(by: (row >> 1) * Int(buffer.strideV))
        
        for x in 0..<width {
            let y = Int16(yLine[x])
            let u = Int16(uLine[x >> 1]) - 128
            let v = Int16(vLine[x >> 1]) - 128
            
            let r = Int16(roundf(Float(y) + Float(v) * 1.4))
            let g = Int16(roundf(Float(y) + Float(u) * -0.343 + Float(v) * -0.711))
            let b = Int16(roundf(Float(y) + Float(u) * 1.765))
            
            let rgb = rgbBuffer.advanced(by: (row * width + x) * bytesPerPixel).assumingMemoryBound(to: UInt8.self)
            rgb[0] = 0xff
            rgb[1] = clamp(value: b)
            rgb[2] = clamp(value: g)
            rgb[3] = clamp(value: r)
        }
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    guard let context = CGContext(data: rgbBuffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * bytesPerPixel, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue).rawValue) else {
        return nil
    }
    
    if let cgImage = context.makeImage() {
        let image = UIImage(cgImage: cgImage)
        return image
    }
        
    return nil
}

func clamp(value: Int16) -> UInt8 {
    return UInt8(min(max(value, 0), 255))
}
