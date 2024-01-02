//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import StreamWebRTC
import MetalKit
import Combine

public struct LocalVideoView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    private let callSettings: CallSettings
    private var viewFactory: Factory
    private var participant: CallParticipant
    private var idSuffix: String
    private var call: Call?
    private var availableFrame: CGRect

    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        idSuffix: String = "local",
        callSettings: CallSettings,
        call: Call?,
        availableFrame: CGRect
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.idSuffix = idSuffix
        self.callSettings = callSettings
        self.call = call
        self.availableFrame = availableFrame
    }
            
    public var body: some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: "\(streamVideo.user.id)-\(idSuffix)",
            availableFrame: availableFrame,
            contentMode: .scaleAspectFill,
            customData: ["videoOn": .bool(callSettings.videoOn)],
            call: call
        )
        .adjustVideoFrame(to: availableFrame.width, ratio: availableFrame.width / availableFrame.height)
        .rotation3DEffect(
            .degrees(shouldRotate ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
    }
    
    private var shouldRotate: Bool {
        callSettings.cameraPosition == .front && callSettings.videoOn
    }
    
}

public struct VideoRendererView: UIViewRepresentable {

    public typealias UIViewType = VideoRenderer

    @Injected(\.utils) var utils
    @Injected(\.colors) var colors

    var id: String
    
    var size: CGSize

    var contentMode: UIView.ContentMode
    
    /// The parameter is used as an optimisation that works with the ViewRenderer Cache that's in place.
    /// In cases where there is no video available, we will render a dummy VideoRenderer that won't try
    /// to get a handle on the cached VideoRenderer, resolving the issue where video tracks may get dark.
    var showVideo: Bool

    var handleRendering: (VideoRenderer) -> Void

    public init(
        id: String,
        size: CGSize,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        showVideo: Bool = true,
        handleRendering: @escaping (VideoRenderer) -> Void
    ) {
        self.id = id
        self.size = size
        self.handleRendering = handleRendering
        self.showVideo = showVideo
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> VideoRenderer {
        let view = showVideo
        ? utils.videoRendererFactory.view(for: id, size: size)
        : VideoRenderer()
        view.videoContentMode = contentMode
        view.backgroundColor = colors.participantBackground
        if showVideo {
            handleRendering(view)
        }
        return view
    }
    
    public func updateUIView(_ uiView: VideoRenderer, context: Context) {
        if showVideo {
            handleRendering(uiView)
        }
    }
}

public class VideoRenderer: RTCMTLVideoView {

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    let queue = DispatchQueue(label: "video-track")
    
    weak var track: RTCVideoTrack?
    
    var feedFrames: ((CMSampleBuffer) -> ())?
    
    private let identifier = UUID()
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
        log.debug("\(type(of: self)):\(identifier) deallocating", subsystems: .webRTC)
        track?.remove(self)
    }

    public override var hash: Int { identifier.hashValue }

    public func add(track: RTCVideoTrack) {
        queue.sync {
            self.track?.remove(self)
            self.track = nil
            self.track = track
            track.add(self)
            log.info("\(type(of: self)):\(identifier) was added on track:\(track.trackId)", subsystems: .webRTC)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.viewSize = bounds.size
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
                let reductionFactor = UIDevice.current.isIpad ? 4 : 6
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
            log.info("Found \(track.kind) track:\(track.trackId) for \(participant.name) and will add on \(type(of: self)):\(identifier))", subsystems: .webRTC)
            self.add(track: track)
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self else { return }
                let prev = participant.trackSize
                if let viewSize, prev != viewSize {
                    log.debug("Update trackSize of \(track.kind) track for \(participant.name) on \(type(of: self)):\(identifier)), \(prev) → \(viewSize)", subsystems: .webRTC)
                    onTrackSizeUpdate(viewSize, participant)
                }
            }
        }
    }
}
