//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

/// A view that wraps a `VideoRenderer` and integrates with SwiftUI.
public struct TrackVideoRendererView: UIViewRepresentable, Equatable {
    /// The type of the `UIView` being represented.
    public typealias UIViewType = TrackVideoRenderer

    public typealias SizeUpdater = (CGSize) -> Void

    /// Injected dependency for accessing color configurations.
    @Injected(\.colors) var colors

    var track: RTCVideoTrack

    /// The content mode for the video renderer.
    var contentMode: UIView.ContentMode

    var sizeUpdater: SizeUpdater

    /// Initializes a new instance of `VideoRendererView`.
    /// - Parameters:
    ///   - id: The identifier for the video renderer.
    ///   - size: The size of the video renderer view.
    ///   - contentMode: The content mode for the video renderer. Default is `.scaleAspectFill`.
    ///   - showVideo: A flag to determine whether video should be shown. Default is `true`.
    ///   - handleRendering: A closure to handle the rendering of the video.
    public init(
        track: RTCVideoTrack,
        contentMode: UIView.ContentMode = .scaleAspectFill,
        sizeUpdater: @escaping SizeUpdater
    ) {
        self.track = track
        self.contentMode = contentMode
        self.sizeUpdater = sizeUpdater
    }

    /// Dismantles the `UIView` when it is no longer needed.
    /// - Parameters:
    ///   - uiView: The `VideoRenderer` to dismantle.
    ///   - coordinator: The coordinator associated with the view.
    public static func dismantleUIView(
        _ uiView: UIViewType,
        coordinator: Coordinator
    ) {
        coordinator.dismantle()
    }

    nonisolated public static func == (
        lhs: TrackVideoRendererView,
        rhs: TrackVideoRendererView
    ) -> Bool {
        lhs.track.trackId == rhs.track.trackId
    }

    /// Creates the `VideoRenderer` view.
    /// - Parameter context: The context containing information about the current state of the system.
    /// - Returns: A configured `VideoRenderer` instance.
    public func makeUIView(context: Context) -> UIViewType {
        context.coordinator.renderer.videoContentMode = contentMode
        context.coordinator.renderer.contentMode = contentMode
        context.coordinator.renderer.backgroundColor = colors.participantBackground
        return context.coordinator.renderer
    }

    /// Updates the `VideoRenderer` view when the state changes.
    /// - Parameters:
    ///   - uiView: The `VideoRenderer` to update.
    ///   - context: The context containing information about the current state of the system.
    public func updateUIView(_ uiView: UIViewType, context: Context) {}

    /// Creates the coordinator for managing the view.
    /// - Returns: A new `Coordinator` instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator(track: track, sizeUpdater: sizeUpdater)
    }
}

/// Extension for `VideoRendererView` to define the `Coordinator` class.
extension TrackVideoRendererView {
    /// A class to coordinate the `VideoRendererView` and manage its lifecycle.
    public final class Coordinator: @unchecked Sendable {

        /// A closure to handle the rendering of the video.
        private let sizeUpdater: SizeUpdater
        /// A disposable bag to manage cancellable subscriptions.
        private let disposableBag = DisposableBag()

        /// The video renderer managed by this coordinator.
        fileprivate let renderer: TrackVideoRenderer

        /// Initializes a new instance of the coordinator.
        /// - Parameter handleRendering: A closure to handle the rendering of the video.
        @MainActor
        init(track: RTCVideoTrack, sizeUpdater: @escaping SizeUpdater) {
            self.sizeUpdater = sizeUpdater
            renderer = .init(track: track)
            setupRendererObservation()
        }

        deinit {
            dismantle()
        }

        /// Dismantles the video renderer and releases resources.
        func dismantle() {
            disposableBag.removeAll()
        }

        // MARK: Private API

        /// Sets up observation for the renderer's window and superview.
        @MainActor
        private func setupRendererObservation() {
            renderer
                .framePublisher
                .map(\.size)
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sinkTask(storeIn: disposableBag) { [weak self] in self?.sizeUpdater($0) }
                .store(in: disposableBag)
        }
    }
}
