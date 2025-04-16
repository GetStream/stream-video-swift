//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import UIKit

/// Manages Picture-in-Picture functionality for video calls.
///
/// Coordinates between the call, source view, and Picture-in-Picture system components.
public final class StreamPictureInPictureAdapter: @unchecked Sendable {

    /// The active call instance.
    public var call: Call? { willSet { store.dispatch(.setCall(newValue)) } }

    /// The view used as an anchor for Picture-in-Picture display.
    public var sourceView: UIView? { willSet { store.dispatch(.setSourceView(newValue)) } }

    let store: PictureInPictureStore = .init()

    private let disposableBag = DisposableBag()
    private var pictureInPictureController: Any?

    private lazy var contentProvider: PictureInPictureContentProvider = .init(store: store)
    private lazy var trackStateAdapter: PictureInPictureTrackStateAdapter = .init(store: store)

    /// Creates a new Picture-in-Picture adapter.
    init() {
        Task { @MainActor in
            guard
                #available(iOS 15.0, *),
                let pictureInPictureController = PictureInPictureController(store: store)
            else {
                log.warning("Not supported.", subsystems: .pictureInPicture)
                return
            }

            self.pictureInPictureController = pictureInPictureController

            _ = contentProvider
            _ = trackStateAdapter

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
                .log(.debug, subsystems: .pictureInPicture) { "SourceView updated: \($0?.description ?? "-")." }
                .sink { _ in }
                .store(in: disposableBag)
        }
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
