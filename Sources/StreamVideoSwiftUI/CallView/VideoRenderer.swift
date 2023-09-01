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
    
    public init(
        id: String,
        size: CGSize,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        handleRendering: @escaping (VideoRenderer) -> Void
    ) {
        self.id = id
        self.size = size
        self.handleRendering = handleRendering
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> VideoRenderer {
        let view = utils.videoRendererFactory.view(for: id, size: size)
        view.videoContentMode = contentMode
        view.backgroundColor = UIColor.black
        handleRendering(view)
        return view
    }
    
    public func updateUIView(_ uiView: VideoRenderer, context: Context) {
        handleRendering(uiView)
    }
}

public class VideoRenderer: RTCMTLVideoView {
    
    let queue = DispatchQueue(label: "video-track")
    
    weak var track: RTCVideoTrack?
    
    var feedFrames: ((CMSampleBuffer) -> ())?
    
    private var skipNextFrameRendering = true
    
    var trackId: String? {
        self.track?.trackId
    }
    
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
        
        guard let feedFrames else { return }
        
        skipNextFrameRendering.toggle()
        if skipNextFrameRendering {
           return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            guard let frame = frame else {
                return
            }

            if let pixelBuffer = frame.buffer as? RTCCVPixelBuffer {
                guard let sampleBuffer = CMSampleBuffer.from(pixelBuffer.pixelBuffer) else {
                    log.warning("Failed to convert CVPixelBuffer to CMSampleBuffer")
                    return
                }

                feedFrames(sampleBuffer)
            } else if let i420buffer = frame.buffer as? RTCI420Buffer {
                // We reduce the track resolution, since it's displayed in a smaller place.
                // Values are picked depending on how much the PiP view takes in an average iPhone or iPad.
                let reductionFactor = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 6
                guard let buffer = convertI420BufferToPixelBuffer(i420buffer, reductionFactor: reductionFactor),
                        let sampleBuffer = CMSampleBuffer.from(buffer) else {
                    return
                }
                
                feedFrames(sampleBuffer)
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
