//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import MetalKit
import StreamVideo
import StreamWebRTC
import SwiftUI

/// A custom video renderer based on RTCMTLVideoView for rendering RTCVideoTrack objects.
public class VideoRenderer: RTCMTLVideoView, @unchecked Sendable {

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    private let _windowSubject: PassthroughSubject<UIWindow?, Never> = .init()
    private let _superviewSubject: PassthroughSubject<UIView?, Never> = .init()
    private let _frameSubject: PassthroughSubject<CGRect, Never> = .init()

    var windowPublisher: AnyPublisher<UIWindow?, Never> { _windowSubject.eraseToAnyPublisher() }
    var superviewPublisher: AnyPublisher<UIView?, Never> { _superviewSubject.eraseToAnyPublisher() }
    var framePublisher: AnyPublisher<CGRect, Never> { _frameSubject.eraseToAnyPublisher() }

    /// DispatchQueue for synchronizing access to the video track.
    let rendererAdapter: RTCVideoTrackAdapter = .init(track: nil)

    /// The associated RTCVideoTrack being rendered.
    nonisolated(unsafe) weak var track: RTCVideoTrack?

    var participant: CallParticipant?

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
    private nonisolated(unsafe) var viewSize: CGSize?

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
        log.debug("\(type(of: self)):\(identifier) deallocating", subsystems: .other)
        track?.remove(self)
    }

    /// Overrides the hash value to return the identifier's hash value.
    override public var hash: Int { identifier.hashValue }

    /// Adds the specified RTCVideoTrack to the renderer.
    /// - Parameter track: The RTCVideoTrack to render.
    public func add(track: RTCVideoTrack) {
        rendererAdapter.updateTrack(track)
        rendererAdapter.addRenderer(self)
    }

    /// Overrides the layoutSubviews method to update the viewSize property.
    override public func layoutSubviews() {
        super.layoutSubviews()
        viewSize = bounds.size
        _frameSubject.send(frame)
    }

    override public func willMove(toWindow newWindow: UIWindow?) {
        _windowSubject.send(newWindow)
        super.willMove(toWindow: newWindow)
    }

    /// Overrides the willMove(toSuperview:) method to release the renderer when removed from its superview.
    override public func willMove(toSuperview newSuperview: UIView?) {
        _superviewSubject.send(newSuperview)
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            // Clean up any rendered frames.
            setSize(.zero)
            rendererAdapter.removeRenderer(self)
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
        onTrackSizeUpdate: @escaping @Sendable(CGSize, CallParticipant) -> Void
    ) {
        if let track = participant.track {
            log.info(
                "Found \(track.kind) track:\(track.trackId) for \(participant.name) and will add on \(type(of: self)):\(identifier)) isMuted:\(!track.isEnabled)",
                subsystems: .other
            )
            self.participant = participant
            add(track: track)
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self else { return }
                let prev = participant.trackSize
                if let viewSize, prev != viewSize {
                    log.debug(
                        "Update trackSize of \(track.kind) track for \(participant.name) on \(type(of: self)):\(identifier)), \(prev) → \(viewSize)",
                        subsystems: .other
                    )
                    onTrackSizeUpdate(viewSize, participant)
                }
            }
        } else {
            log.debug(
                "Participant id:\(participant.id) doesn't have a track. trackLookUpPrefix:\(participant.trackLookupPrefix ?? "n/a").",
                subsystems: .webRTC
            )
        }
    }
}

final class RTCVideoTrackAdapter {

    private let queue = UnfairQueue()
    private var track: RTCVideoTrack?
    private var renderers: [RTCVideoRenderer] = []

    init(track: RTCVideoTrack?) {
        self.track = track
    }

    deinit {
        removeAll()
    }

    func updateTrack(_ newTrack: RTCVideoTrack?) {
        guard let newTrack else {
            removeAll()
            self.track = nil
            return
        }

        guard newTrack.trackId != track?.trackId else {
            return
        }

        removeAll()
        self.track = newTrack
    }

    func addRenderer(_ renderer: RTCVideoRenderer) {
        queue.sync {
            guard
                let track,
                !renderers.contains(where: { $0 === renderer })
            else {
                return
            }
            track.add(renderer)
            renderers.append(renderer)
        }
    }

    func removeRenderer(_ renderer: RTCVideoRenderer) {
        queue.sync {
            guard let track else { return }
            track.remove(renderer)
            renderers = renderers.filter { $0 !== renderer }
        }
    }

    private func removeAll() {
        let oldRenderers = queue.sync {
            let result = self.renderers
            self.renderers = []
            return result
        }
        oldRenderers.forEach { self.track?.remove($0) }
    }
}

