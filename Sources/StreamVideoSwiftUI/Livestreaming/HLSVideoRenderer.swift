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

    /// Creates a renderer for the HLS stream of the call.
    /// - Parameters:
    ///   - call: The call that plays HLS.
    ///   - contentMode: How the video fits the view. Defaults to
    ///     `.scaleAspectFit`.
    public init(
        call: Call,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.init(call: call, contentMode: contentMode, store: .shared)
    }

    init(
        call: Call,
        contentMode: UIView.ContentMode,
        store: HLSPlayerStore
    ) {
        self.call = call
        self.contentMode = contentMode
        self.store = store
    }

    /// Creates the coordinator that owns the claim on the player.
    public func makeCoordinator() -> Coordinator {
        Coordinator(call: call, store: store)
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

        init(call: Call, store: HLSPlayerStore) {
            self.call = call
            self.store = store
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
                if lease == nil {
                    lease = store.acquire(for: call, playbackType: playbackType)
                }
            case .webRTC:
                lease?.release()
                lease = nil
            }
            view?.player = lease?.player
        }
    }
}

/// A view whose layer shows the frames of an `AVPlayer`.
public final class HLSPlayerView: UIView {

    override public class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer {
        // The class property makes the layer an `AVPlayerLayer`.
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var videoGravity: AVLayerVideoGravity {
        get { playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
}
