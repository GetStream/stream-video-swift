//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo
import SwiftUI
import UIKit

/// A view that plays the HLS stream of a call.
///
/// The backend routes a viewer to HLS when it joins. Check
/// ``CallState/playbackType`` for `.hls`, and use this view instead of the
/// participant video views. Every renderer of the same call uses the same
/// player, so the stream is loaded once. An `AVPlayer` draws in only one
/// layer at a time, the most recently created, so show one renderer per call
/// at a time.
///
/// The renderer stays empty while the call does not play HLS, and fills as
/// soon as it does.
public struct HLSVideoRendererView: UIViewRepresentable {

    /// The type of the `UIView` being represented.
    ///
    /// The view that hosts the player is internal, so it is exposed as a
    /// `UIView`.
    public typealias UIViewType = UIView

    /// The call that plays HLS.
    var call: Call

    /// How the video fits the view.
    var contentMode: UIView.ContentMode

    /// Initializes a new instance of `HLSVideoRendererView`.
    /// - Parameters:
    ///   - call: The call that plays HLS.
    ///   - contentMode: How the video fits the view. Default is
    ///     `.scaleAspectFit`.
    public init(
        call: Call,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.call = call
        self.contentMode = contentMode
    }

    /// Creates the view that shows the player of the call.
    /// - Parameter context: The context containing information about the
    ///   current state of the system.
    /// - Returns: A configured view that hosts the HLS player.
    public func makeUIView(context: Context) -> UIView {
        let view = HLSPlayerView()
        view.backgroundColor = .clear
        view.videoGravity = videoGravity(for: contentMode)
        context.coordinator.attach(to: view)
        return view
    }

    /// Updates the view when the state changes.
    /// - Parameters:
    ///   - uiView: The view that hosts the HLS player.
    ///   - context: The context containing information about the current
    ///     state of the system.
    public func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? HLSPlayerView else { return }
        view.videoGravity = videoGravity(for: contentMode)
        context.coordinator.update(call: call)
    }

    /// Creates the coordinator that shows the player of the call.
    /// - Returns: A new `Coordinator` instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator(call: call)
    }

    /// Clears the view when it goes away. The player stays with the call.
    /// - Parameters:
    ///   - uiView: The view that hosts the HLS player.
    ///   - coordinator: The coordinator associated with the view.
    public static func dismantleUIView(
        _ uiView: UIView,
        coordinator: Coordinator
    ) {
        coordinator.dismantle()
    }

    private func videoGravity(
        for contentMode: UIView.ContentMode
    ) -> AVLayerVideoGravity {
        switch contentMode {
        case .scaleAspectFill:
            return .resizeAspectFill
        case .scaleToFill:
            return .resize
        default:
            return .resizeAspect
        }
    }
}
