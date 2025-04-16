//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import UIKit

/// This class encapsulates the logic for managing picture-in-picture functionality during a video call. It tracks
/// changes in the call, updates related to call participants, and changes in the source view for Picture in
/// Picture display.
public final class StreamPictureInPictureAdapter: @unchecked Sendable {

    /// The active call.
    public var call: Call? { willSet { store.dispatch(.setCall(newValue)) } }

    /// The sourceView that will be used as an anchor/trigger for picture-in-picture (as required by AVKit).
    public var sourceView: UIView? { willSet { store.dispatch(.setSourceView(newValue)) } }

    private let store: PictureInPictureStore = .init()
    private let disposableBag = DisposableBag()
    private var pictureInPictureController: Any?

    private lazy var contentProvider: PictureInPictureContentProvider = .init(store: store)
    private lazy var trackStateAdapter: StreamPictureInPictureTrackStateAdapter = .init(store: store)

    init() {
        Task { @MainActor in
            guard
                #available(iOS 15.0, *),
                let pictureInPictureController = StreamPictureInPictureController(store: store)
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

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
enum StreamPictureInPictureAdapterKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamPictureInPictureAdapter = .init()
}

extension InjectedValues {
    /// Provides access to the `StreamPictureInPictureAdapter` class to the views and view models.
    public var pictureInPictureAdapter: StreamPictureInPictureAdapter {
        get {
            Self[StreamPictureInPictureAdapterKey.self]
        }
        set {
            Self[StreamPictureInPictureAdapterKey.self] = newValue
        }
    }
}
