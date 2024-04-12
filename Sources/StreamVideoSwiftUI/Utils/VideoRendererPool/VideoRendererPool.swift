//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

/// A pool for managing reusable `VideoRenderer` instances.
final class VideoRendererPool {
    /// The underlying pool of `VideoRenderer` instances managed by this pool.
    private let pool: ReusePool<VideoRenderer>
    /// A cancellable object to observe call end notifications for releasing all renderers.
    private var callEndedCancellable: AnyCancellable?

    /// Initializes the `VideoRendererPool` with a specified initial capacity.
    ///
    /// - Parameter initialCapacity: The initial capacity of the pool (default is 10).
    init(initialCapacity: Int = 10) {
        // Initialize the pool with a capacity and a factory closure to create `VideoRenderer` instances
        pool = ReusePool(initialCapacity: initialCapacity) {
            VideoRenderer(frame: CGRect(origin: .zero, size: .zero))
        }

        // Observe call end notifications to release all renderers when a call ends
        callEndedCancellable = NotificationCenter.default.publisher(for: Notification.Name(CallNotification.callEnded))
            .sink { [weak self] _ in
                self?.pool.releaseAll()
            }
    }

    /// Acquires a `VideoRenderer` from the pool with the specified size.
    ///
    /// - Parameter size: The desired size for the acquired `VideoRenderer`.
    /// - Returns: A `VideoRenderer` instance from the pool.
    func acquireRenderer(size: CGSize) -> VideoRenderer {
        let renderer = pool.acquire()
        renderer.frame.size = size // Set the size of the renderer
        return renderer
    }

    /// Releases a `VideoRenderer` back to the pool for reuse.
    ///
    /// - Parameter renderer: The `VideoRenderer` instance to release.
    func releaseRenderer(_ renderer: VideoRenderer) {
        pool.release(renderer)
    }
}

extension VideoRendererPool: InjectionKey {
    static var currentValue: VideoRendererPool = .init()
}

extension InjectedValues {
    var videoRendererPool: VideoRendererPool {
        get { Self[VideoRendererPool.self] }
        set { _ = newValue }
    }
}
