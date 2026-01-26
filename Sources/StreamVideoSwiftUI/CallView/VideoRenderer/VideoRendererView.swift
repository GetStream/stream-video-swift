//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view that wraps a `VideoRenderer` and integrates with SwiftUI.
public struct VideoRendererView: UIViewRepresentable {

    /// The type of the `UIView` being represented.
    public typealias UIViewType = VideoRenderer

    /// Injected dependency for accessing color configurations.
    @Injected(\.colors) var colors

    /// The identifier for the video renderer.
    var id: String

    /// The size of the video renderer view.
    var size: CGSize

    /// The content mode for the video renderer.
    var contentMode: UIView.ContentMode

    /// A flag to determine whether video should be shown. Optimizes rendering by using a dummy renderer when false.
    var showVideo: Bool

    /// A closure to handle the rendering of the video.
    var handleRendering: (VideoRenderer) -> Void

    /// Initializes a new instance of `VideoRendererView`.
    /// - Parameters:
    ///   - id: The identifier for the video renderer.
    ///   - size: The size of the video renderer view.
    ///   - contentMode: The content mode for the video renderer. Default is `.scaleAspectFill`.
    ///   - showVideo: A flag to determine whether video should be shown. Default is `true`.
    ///   - handleRendering: A closure to handle the rendering of the video.
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

    /// Dismantles the `UIView` when it is no longer needed.
    /// - Parameters:
    ///   - uiView: The `VideoRenderer` to dismantle.
    ///   - coordinator: The coordinator associated with the view.
    public static func dismantleUIView(
        _ uiView: VideoRenderer,
        coordinator: Coordinator
    ) {
        coordinator.dismantle()
    }

    /// Creates the `VideoRenderer` view.
    /// - Parameter context: The context containing information about the current state of the system.
    /// - Returns: A configured `VideoRenderer` instance.
    public func makeUIView(context: Context) -> VideoRenderer {
        context.coordinator.renderer.frame = .init(
            origin: context.coordinator.renderer.frame.origin,
            size: size
        )
        context.coordinator.renderer.videoContentMode = contentMode
        context.coordinator.renderer.backgroundColor = colors.participantBackground

        if showVideo {
            handleRendering(context.coordinator.renderer)
        }
        return context.coordinator.renderer
    }

    /// Updates the `VideoRenderer` view when the state changes.
    /// - Parameters:
    ///   - uiView: The `VideoRenderer` to update.
    ///   - context: The context containing information about the current state of the system.
    public func updateUIView(_ uiView: VideoRenderer, context: Context) {
        if showVideo {
            handleRendering(uiView)
        }
    }

    /// Creates the coordinator for managing the view.
    /// - Returns: A new `Coordinator` instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator(handleRendering: handleRendering)
    }
}

/// Extension for `VideoRendererView` to define the `Coordinator` class.
extension VideoRendererView {
    /// A class to coordinate the `VideoRendererView` and manage its lifecycle.
    public final class Coordinator: @unchecked Sendable {
        /// Injected dependency for accessing the video renderer pool.
        @Injected(\.videoRendererPool) private var videoRendererPool

        /// A closure to handle the rendering of the video.
        private let handleRendering: ((VideoRenderer) -> Void)?
        /// A disposable bag to manage cancellable subscriptions.
        private let disposableBag = DisposableBag()

        /// The video renderer managed by this coordinator.
        fileprivate let renderer: VideoRenderer

        /// Initializes a new instance of the coordinator.
        /// - Parameter handleRendering: A closure to handle the rendering of the video.
        @MainActor
        init(handleRendering: ((VideoRenderer) -> Void)?) {
            self.handleRendering = handleRendering
            renderer = VideoRendererPool
                .currentValue
                .acquireRenderer(size: .zero)
            setupRendererObservation()
        }

        deinit {
            dismantle()
        }

        /// Dismantles the video renderer and releases resources.
        func dismantle() {
            renderer.track?.remove(renderer)
            disposableBag.removeAll()
            videoRendererPool.releaseRenderer(renderer)
        }

        // MARK: Private API

        /// Sets up observation for the renderer's window and superview.
        @MainActor
        private func setupRendererObservation() {
            renderer
                .windowPublisher
                .map { $0 != nil }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard
                        $0,
                        let handleRendering = self?.handleRendering,
                        let renderer = self?.renderer
                    else { return }
                    handleRendering(renderer)
                }
                .store(in: disposableBag)

            renderer
                .superviewPublisher
                .map { $0 != nil }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard
                        $0,
                        let handleRendering = self?.handleRendering,
                        let renderer = self?.renderer
                    else { return }
                    handleRendering(renderer)
                }
                .store(in: disposableBag)
        }
    }
}
