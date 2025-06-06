//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view that wraps a `VideoRenderer` and integrates with SwiftUI.
public struct VideoRendererView: UIViewRepresentable {

    /// The type of the `UIView` being represented.
    public typealias UIViewType = UIView

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
        _ uiView: UIView,
        coordinator: Coordinator
    ) {
        coordinator.dismantle()
    }

    /// Creates the `VideoRenderer` view.
    /// - Parameter context: The context containing information about the current state of the system.
    /// - Returns: A configured `VideoRenderer` instance.
    public func makeUIView(context: Context) -> UIView {
        return context.coordinator.containerView
    }

    /// Updates the `VideoRenderer` view when the state changes.
    /// - Parameters:
    ///   - uiView: The `VideoRenderer` to update.
    ///   - context: The context containing information about the current state of the system.
    public func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateContainerContents(showVideo: showVideo)
    }

    /// Creates the coordinator for managing the view.
    /// - Returns: A new `Coordinator` instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            size: size,
            showVideo: showVideo,
            colors: colors,
            handleRendering: handleRendering
        )
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
        private let size: CGSize
        private let showVideo: Bool
        private let colors: Colors

        /// The video renderer managed by this coordinator.
        fileprivate var renderer: VideoRenderer?

        /// Placeholder until real renderer is ready
        lazy var placeholderRenderer: VideoRenderer = {
            let placeholder = VideoRenderer(frame: .init(origin: .zero, size: size))
            placeholder.backgroundColor = colors.participantBackground
            return placeholder
        }()
        
        lazy var containerView: UIView = {
            let container = UIView(frame: .init(origin: .zero, size: size))
            container.backgroundColor = colors.participantBackground
            container.clipsToBounds = true
            
            // Start with placeholder
            container.addSubview(placeholderRenderer)
            placeholderRenderer.frame = container.bounds
            placeholderRenderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            return container
        }()
        private var hasSwappedToRealRenderer = false

        // Task to track async renderer acquisition
        private var rendererTask: Task<Void, Never>?

        /// Initializes a new instance of the coordinator.
        /// - Parameter handleRendering: A closure to handle the rendering of the video.
        @MainActor
        init(
            size: CGSize,
            showVideo: Bool,
            colors: Colors,
            handleRendering: ((VideoRenderer) -> Void)?
        ) {
            self.size = size
            self.showVideo = showVideo
            self.colors = colors
            self.handleRendering = handleRendering

            // Acquire renderer asynchronously to not block UI
            rendererTask = Task { @MainActor in
                // Acquire the renderer (this might take 100-300ms)
                let renderer = VideoRendererPool
                    .currentValue
                    .acquireRenderer(size: size)
                
                // Store it
                self.renderer = renderer

                // Set up observation
                self.setupRendererObservation()
                
                // Configure the renderer
                renderer.frame = .init(origin: .zero, size: size)
                renderer.videoContentMode = .scaleAspectFill
                renderer.backgroundColor = colors.participantBackground
                
                self.updateContainerContents(showVideo: self.showVideo)
            }
        }

        deinit {
            rendererTask?.cancel()
            dismantle()
        }

        /// Dismantles the video renderer and releases resources.
        func dismantle() {
            disposableBag.removeAll()
            if let renderer {
                renderer.track?.remove(renderer)
                videoRendererPool.releaseRenderer(renderer)
            }
        }
        
        func updateContainerContents(showVideo: Bool) {
            // Swap to real renderer when ready
            if let renderer = renderer, !hasSwappedToRealRenderer {
                placeholderRenderer.removeFromSuperview()
                containerView.addSubview(renderer)
                renderer.frame = containerView.bounds
                renderer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                hasSwappedToRealRenderer = true
                
                // Call handleRendering if showVideo is true
                if showVideo {
                    // Delay handleRendering to ensure view hierarchy is settled
                    DispatchQueue.main.async { [weak self] in
                        self?.handleRendering?(renderer)
                    }
                }
            } else if let renderer = renderer, hasSwappedToRealRenderer && showVideo {
                handleRendering?(renderer)
            }
        }

        // MARK: Private API

        /// Sets up observation for the renderer's window and superview.
        @MainActor
        private func setupRendererObservation() {
            guard let renderer else { return }

            renderer
                .windowPublisher
                .map { $0 != nil }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sinkTask(storeIn: disposableBag) { [weak self] in
                    guard let self else { return }
                    if $0 { handleRendering?(renderer) }
                }
                .store(in: disposableBag)

            renderer
                .superviewPublisher
                .map { $0 != nil }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sinkTask(storeIn: disposableBag) { [weak self] in
                    guard let self else { return }
                    if $0 { handleRendering?(renderer) }
                }
                .store(in: disposableBag)
        }
    }
}
