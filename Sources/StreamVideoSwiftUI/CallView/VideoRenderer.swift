//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI
import WebRTC
import MetalKit
import Combine

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
                availableFrame: reader.frame(in: .global),
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
    
    @Injected(\.thermalStateObserver) private var thermalStateObserver

    let queue = DispatchQueue(label: "video-track")
    
    weak var track: RTCVideoTrack?
    
    var feedFrames: ((CMSampleBuffer) -> ())?
    
    private var skipNextFrameRendering = true
    private var cancellable: AnyCancellable?

    private(set) var preferredFramesPerSecond: Int = UIScreen.main.maximumFramesPerSecond {
        didSet {
            metalView?.preferredFramesPerSecond = preferredFramesPerSecond
            log.debug("🔄 preferredFramesPerSecond was updated to \(preferredFramesPerSecond).")
        }
    }
    private lazy var metalView: MTKView? = { subviews.compactMap { $0 as? MTKView }.first }()
    var trackId: String? { self.track?.trackId }
    private var viewSize: CGSize?
    private var scale: CGFloat { thermalStateObserver.scale }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        cancellable = thermalStateObserver
            .statePublisher
            .sink { [weak self] in
                switch $0 {
                case .nominal, .fair:
                    self?.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
                case .serious:
                    self?.preferredFramesPerSecond = Int(Double(UIScreen.main.maximumFramesPerSecond) * 0.5)
                case .critical:
                    self?.preferredFramesPerSecond = Int(Double(UIScreen.main.maximumFramesPerSecond) * 0.4)
                @unknown default:
                    self?.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
                }
            }
    }

    deinit {
        cancellable?.cancel()
        log.debug("Deinit of video view")
        track?.remove(self)
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
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.viewSize = CGSize(
            width: self.bounds.size.width * scale,
            height: self.bounds.size.height * scale
        )
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
}

extension VideoRenderer {
    
    public func handleViewRendering(
        for participant: CallParticipant,
        onTrackSizeUpdate: @escaping (CGSize, CallParticipant) -> ()
    ) {
        if let track = participant.track {
            log.debug("adding track to a view \(self)")
            self.add(track: track)
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self else { return }
                let prev = participant.trackSize
                if let viewSize, prev != viewSize {
                    onTrackSizeUpdate(viewSize, participant)
                }
            }
        }
    }
    
}
