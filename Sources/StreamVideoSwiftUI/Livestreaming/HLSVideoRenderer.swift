//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
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
public struct HLSVideoRenderer: UIViewRepresentable {

    /// The type of the `UIView` being represented.
    public typealias UIViewType = HLSPlayerView

    var call: Call
    var contentMode: UIView.ContentMode
    var store: HLSPlayerStore
    var onPlayerReady: (() -> Void)?

    /// Creates a renderer for the HLS stream of the call.
    /// - Parameters:
    ///   - call: The call that plays HLS.
    ///   - contentMode: How the video fits the view. Defaults to
    ///     `.scaleAspectFit`.
    public init(
        call: Call,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.init(
            call: call,
            contentMode: contentMode,
            store: InjectedValues[\.hlsPlayerStore]
        )
    }

    init(
        call: Call,
        contentMode: UIView.ContentMode,
        store: HLSPlayerStore,
        onPlayerReady: (() -> Void)? = nil
    ) {
        self.call = call
        self.contentMode = contentMode
        self.store = store
        self.onPlayerReady = onPlayerReady
    }

    /// Creates the coordinator that owns the claim on the player.
    public func makeCoordinator() -> Coordinator {
        Coordinator(call: call, store: store, onPlayerReady: onPlayerReady)
    }

    /// Creates the view that shows the player.
    public func makeUIView(context: Context) -> HLSPlayerView {
        let view = HLSPlayerView()
        view.backgroundColor = .clear
        view.videoGravity = Self.videoGravity(for: contentMode)
        context.coordinator.attach(to: view)
        return view
    }

    /// Applies the content mode.
    public func updateUIView(_ uiView: HLSPlayerView, context: Context) {
        uiView.videoGravity = Self.videoGravity(for: contentMode)
        context.coordinator.update(call: call)
    }

    /// Gives the player back when the view goes away.
    public static func dismantleUIView(
        _ uiView: HLSPlayerView,
        coordinator: Coordinator
    ) {
        coordinator.dismantle()
    }

    static func videoGravity(for contentMode: UIView.ContentMode) -> AVLayerVideoGravity {
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

extension HLSVideoRenderer {

    /// Owns the claim on the shared player for one renderer.
    @MainActor
    public final class Coordinator {

        private var call: Call
        private let store: HLSPlayerStore
        private var lease: HLSPlayerLease?
        private weak var view: HLSPlayerView?
        private var playbackTypeObserver: AnyCancellable?
        /// Called after a new player is shown. Lets the owner apply state,
        /// such as mute, that a player created earlier would not have.
        private let onPlayerReady: (() -> Void)?

        init(
            call: Call,
            store: HLSPlayerStore,
            onPlayerReady: (() -> Void)? = nil
        ) {
            self.call = call
            self.store = store
            self.onPlayerReady = onPlayerReady
        }

        func attach(to view: HLSPlayerView) {
            self.view = view
            observePlaybackType()
        }

        /// Follows `call` when the view is given another one.
        func update(call newCall: Call) {
            guard newCall.cId != call.cId else { return }
            playbackTypeObserver = nil
            lease?.release()
            lease = nil
            call = newCall
            observePlaybackType()
        }

        func dismantle() {
            playbackTypeObserver = nil
            lease?.release()
            lease = nil
            view?.player = nil
        }

        private func observePlaybackType() {
            playbackTypeObserver = call.state
                .$playbackType
                .removeDuplicates()
                .sink { [weak self] in self?.update(for: $0) }
        }

        private func update(for playbackType: PlaybackType) {
            switch playbackType {
            case .hls:
                guard lease == nil else { return }
                lease = store.acquire(for: call, playbackType: playbackType)
                view?.player = lease?.player
                if lease != nil { onPlayerReady?() }
            case .webRTC:
                lease?.release()
                lease = nil
                view?.player = nil
            }
        }
    }
}
