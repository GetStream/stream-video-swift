//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import MetalKit
import StreamVideo
import StreamWebRTC
import SwiftUI

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
    }
}

public struct VideoRendererView: UIViewRepresentable {

    public typealias UIViewType = VideoRenderer

    @Injected(\.utils) var utils
    @Injected(\.colors) var colors
    @Injected(\.videoRendererPool) private var videoRendererPool

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
        let view = videoRendererPool.acquireRenderer(size: size)
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

/// A custom video renderer based on RTCMTLVideoView for rendering RTCVideoTrack objects.
public class VideoRenderer: RTCMTLVideoView {

    @Injected(\.thermalStateObserver) private var thermalStateObserver
    @Injected(\.videoRendererPool) private var videoRendererPool

    /// DispatchQueue for synchronizing access to the video track.
    let queue = DispatchQueue(label: "video-track")

    /// The associated RTCVideoTrack being rendered.
    weak var track: RTCVideoTrack?

    /// Unique identifier for the video renderer instance.
    private let identifier = UUID()
    private var cancellable: AnyCancellable?

    /// Preferred frames per second for rendering.
    private(set) var preferredFramesPerSecond: Int = UIScreen.main.maximumFramesPerSecond {
        didSet {
            metalView?.preferredFramesPerSecond = preferredFramesPerSecond
            log.debug("🔄 preferredFramesPerSecond was updated to \(preferredFramesPerSecond).")
        }
    }

    /// Lazily-initialized Metal view used for rendering.
    private lazy var metalView: MTKView? = { subviews.compactMap { $0 as? MTKView }.first }()

    /// The ID of the associated RTCVideoTrack.
    var trackId: String? { track?.trackId }

    /// The size of the renderer's view.
    private var viewSize: CGSize?

    /// Required initializer (unavailable for use with Interface Builder).
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Initializes a new VideoRenderer instance with the specified frame.
    /// - Parameter frame: The frame rectangle for the video renderer's view.
    override public init(frame: CGRect) {
        super.init(frame: frame)

        // Subscribe to thermal state changes to adjust rendering performance.
        cancellable = thermalStateObserver
            .statePublisher
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .nominal, .fair:
                    self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
                case .serious:
                    self.preferredFramesPerSecond = Int(Double(UIScreen.main.maximumFramesPerSecond) * 0.5)
                case .critical:
                    self.preferredFramesPerSecond = Int(Double(UIScreen.main.maximumFramesPerSecond) * 0.4)
                @unknown default:
                    self.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
                }
            }
    }

    /// Cleans up resources when the VideoRenderer instance is deallocated.
    deinit {
        cancellable?.cancel()
        log.debug("\(type(of: self)):\(identifier) deallocating", subsystems: .webRTC)
        track?.remove(self)
    }

    /// Overrides the hash value to return the identifier's hash value.
    override public var hash: Int { identifier.hashValue }

    /// Adds the specified RTCVideoTrack to the renderer.
    /// - Parameter track: The RTCVideoTrack to render.
    public func add(track: RTCVideoTrack) {
        queue.sync {
            self.track?.remove(self)
            self.track = nil
            self.track = track
            track.add(self)
            log.info("\(type(of: self)):\(identifier) was added on track:\(track.trackId)", subsystems: .webRTC)
        }
    }

    /// Overrides the layoutSubviews method to update the viewSize property.
    override public func layoutSubviews() {
        super.layoutSubviews()
        viewSize = bounds.size
    }

    /// Overrides the willMove(toSuperview:) method to release the renderer when removed from its superview.
    override public func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            videoRendererPool.releaseRenderer(self)
            // Clean up any rendered frames.
            renderFrame(nil)
        }
    }
}

extension VideoRenderer {

    /// Handles rendering view updates for a specified participant's video track.
    /// - Parameters:
    ///   - participant: The participant whose video track is being handled.
    ///   - onTrackSizeUpdate: A closure to be called when the track size is updated.
    public func handleViewRendering(
        for participant: CallParticipant,
        onTrackSizeUpdate: @escaping (CGSize, CallParticipant) -> Void
    ) {
        if let track = participant.track {
            log.info(
                "Found \(track.kind) track:\(track.trackId) for \(participant.name) and will add on \(type(of: self)):\(identifier))",
                subsystems: .webRTC
            )
            add(track: track)
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self else { return }
                let prev = participant.trackSize
                if let viewSize, prev != viewSize {
                    log.debug(
                        "Update trackSize of \(track.kind) track for \(participant.name) on \(type(of: self)):\(identifier)), \(prev) → \(viewSize)",
                        subsystems: .webRTC
                    )
                    onTrackSizeUpdate(viewSize, participant)
                }
            }
        }
    }
}
