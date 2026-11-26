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
/// participant video views. Every renderer of the same call shows the same
/// player, so the stream is loaded once.
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

    /// Called after a new player is shown, so the owner can apply state, such
    /// as mute, that a player created earlier would not have.
    var onPlayerReady: (@MainActor () async -> Void)?

    /// Initializes a new instance of `HLSVideoRendererView`.
    /// - Parameters:
    ///   - call: The call that plays HLS.
    ///   - contentMode: How the video fits the view. Default is
    ///     `.scaleAspectFit`.
    public init(
        call: Call,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.init(call: call, contentMode: contentMode, onPlayerReady: nil)
    }

    init(
        call: Call,
        contentMode: UIView.ContentMode,
        onPlayerReady: (@MainActor () async -> Void)?
    ) {
        self.call = call
        self.contentMode = contentMode
        self.onPlayerReady = onPlayerReady
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

    /// Creates the coordinator that owns the claim on the player.
    /// - Returns: A new `Coordinator` instance.
    public func makeCoordinator() -> Coordinator {
        Coordinator(call: call, onPlayerReady: onPlayerReady)
    }

    /// Gives the player back when the view goes away.
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
