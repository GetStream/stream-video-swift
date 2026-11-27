//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamVideo
import UIKit

/// Manages Picture-in-Picture functionality for video calls.
///
/// Coordinates between the call, source view, and Picture-in-Picture system components.
public final class StreamPictureInPictureAdapter: @unchecked Sendable {

    /// The active call instance.
    public var call: Call? {
        willSet { store?.dispatch(.setCall(newValue)) }
        didSet { callDidChange.send(call) }
    }

    /// Sends the call each time it is set.
    let callDidChange = PassthroughSubject<Call?, Never>()

    /// The view used as an anchor for Picture-in-Picture display.
    public var sourceView: UIView? { willSet { store?.dispatch(.setSourceView(newValue)) } }

    private(set) var store: PictureInPictureStore?

    /// The HLS layer set before the store existed. The store gets it when it
    /// is created, like the call.
    @MainActor private var pendingPlayerLayer: (layer: AVPlayerLayer, cId: String)?

    private let disposableBag = DisposableBag()
    private var pictureInPictureController: Any?

    private var contentProvider: PictureInPictureContentProvider?
    private var trackStateAdapter: PictureInPictureTrackStateAdapter?

    /// Creates a new Picture-in-Picture adapter.
    init() {
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
            let store = PictureInPictureStore()
            guard
                #available(iOS 15.0, *)
            else {
                log.warning("Not supported.", subsystems: .pictureInPicture)
                return
            }

            /// If the call was updated before we create our store internally, make sure that we will
            /// set the Call correctly.
            if store.state.call?.cId != call?.cId {
                store.dispatch(.setCall(call))
            }

            if let pendingPlayerLayer {
                store.dispatch(.setPlayerLayer(pendingPlayerLayer.layer, cId: pendingPlayerLayer.cId))
            }
            pendingPlayerLayer = nil
            self.store = store
            self.pictureInPictureController = PictureInPictureController(store: store)

            contentProvider = .init(store: store)
            trackStateAdapter = .init(store: store)

            store
                .publisher(for: \.content)
                .removeDuplicates()
                .log(.debug, subsystems: .pictureInPicture) { "Content updated: \($0)." }
                .sink { _ in }
                .store(in: disposableBag)

            Publishers
                .CombineLatest(store.publisher(for: \.call), store.publisher(for: \.sourceView))
                .filter { $0 == nil && $1 != nil }
                .log(.warning, subsystems: .pictureInPicture) { _, _ in
                    """
                    PictureInPicture adapter has received a sourceView but the required
                    call is nil. Please ensure that you provide a call instance in order
                    to activate correctly Picture-in-Picture.
                    """
                }
                .sink { _ in }
                .store(in: disposableBag)

            store
                .publisher(for: \.sourceView)
                .removeDuplicates()
                .log(.debug, subsystems: .pictureInPicture) {
                    "SourceView updated frame:\($0?.frame ?? .zero) hasWindow:\($0?.window != nil)."
                }
                .sink { _ in }
                .store(in: disposableBag)
        }
    }

    // MARK: - State updaters

    /// Lets Picture in Picture show the layer of an HLS player for the call
    /// with `cId`.
    @MainActor
    func setPlayerLayer(_ layer: AVPlayerLayer, cId: String) {
        guard let store else {
            pendingPlayerLayer = (layer, cId)
            return
        }
        store.dispatch(.setPlayerLayer(layer, cId: cId))
    }

    /// Clears the layer, unless Picture in Picture shows another one now.
    @MainActor
    func removePlayerLayer(_ layer: AVPlayerLayer) {
        if pendingPlayerLayer?.layer === layer { pendingPlayerLayer = nil }
        store?.dispatch(.removePlayerLayer(layer))
    }

    /// Updates the ViewFactory instance the will be used by Picture-in-Picture to create UI components.
    @MainActor
    public func setViewFactory<V: ViewFactory>(_ viewFactory: V) {
        guard let store else {
            return
        }
        store.dispatch(.setViewFactory(.init(viewFactory)))
    }
}

/// Provides the default value for the Picture-in-Picture adapter.
enum StreamPictureInPictureAdapterKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamPictureInPictureAdapter = .init()
}

extension InjectedValues {
    /// Access point for the Picture-in-Picture adapter in the dependency injection system.
    public var pictureInPictureAdapter: StreamPictureInPictureAdapter {
        get {
            Self[StreamPictureInPictureAdapterKey.self]
        }
        set {
            Self[StreamPictureInPictureAdapterKey.self] = newValue
        }
    }
}
