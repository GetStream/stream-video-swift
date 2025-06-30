//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import MetalKit
import StreamVideo
import StreamWebRTC
import SwiftUI

/// A custom video renderer based on RTCMTLVideoView for rendering RTCVideoTrack objects.
public class TrackVideoRenderer: RTCMTLVideoView, @unchecked Sendable {

    private let _windowSubject: PassthroughSubject<UIWindow?, Never> = .init()
    private let _superviewSubject: PassthroughSubject<UIView?, Never> = .init()
    private let _frameSubject: PassthroughSubject<CGRect, Never> = .init()

    var windowPublisher: AnyPublisher<UIWindow?, Never> { _windowSubject.eraseToAnyPublisher() }
    var superviewPublisher: AnyPublisher<UIView?, Never> { _superviewSubject.eraseToAnyPublisher() }
    var framePublisher: AnyPublisher<CGRect, Never> { _frameSubject.eraseToAnyPublisher() }

    /// The associated RTCVideoTrack being rendered.
    private let track: RTCVideoTrack
    private let queue = UnfairQueue()
    private var renderingTrack = false

    /// Unique identifier for the video renderer instance.
    private var cancellable: AnyCancellable?

    /// Lazily-initialized Metal view used for rendering.
    private lazy var metalView: MTKView? = { subviews.compactMap { $0 as? MTKView }.first }()

    /// Required initializer (unavailable for use with Interface Builder).
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Initializes a new VideoRenderer instance with the specified frame.
    /// - Parameter frame: The frame rectangle for the video renderer's view.
    public init(track: RTCVideoTrack) {
        self.track = track
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    /// Cleans up resources when the VideoRenderer instance is deallocated.
    deinit {
        track.remove(self)
    }

    /// Overrides the layoutSubviews method to update the viewSize property.
    override public func layoutSubviews() {
        super.layoutSubviews()
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
            removeRendererIfRequired()
        } else {
            addRendererIfRequired()
        }
    }

    private func addRendererIfRequired() {
        queue.sync {
            guard renderingTrack == false else {
                return
            }
            track.add(self)
            renderingTrack = true
        }
    }

    private func removeRendererIfRequired() {
        queue.sync {
            guard renderingTrack else {
                return
            }
            track.remove(self)
            setSize(.zero)
            renderingTrack = false
        }
    }
}
