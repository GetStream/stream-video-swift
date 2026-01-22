//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

/// A pool for managing reusable `VideoRenderer` instances.
final class VideoRendererPool: @unchecked Sendable {
    /// The underlying pool of `VideoRenderer` instances managed by this pool.
    private let pool: ReusePool<VideoRenderer>
    /// A cancellable object to observe call end notifications for releasing all renderers.
    private var callEndedCancellable: AnyCancellable?

    /// Initializes the `VideoRendererPool` with a specified initial capacity.
    ///
    /// - Parameter initialCapacity: The initial capacity of the pool (default is 0).
    @MainActor
    init(initialCapacity: Int = 0) {
        // Initialize the pool with a capacity and a factory closure to create `VideoRenderer` instances
        pool = ReusePool(initialCapacity: initialCapacity) {
            VideoRenderer(frame: CGRect(origin: .zero, size: .zero))
        }

        // Observe call end notifications to release all renderers when a call ends
        callEndedCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .sink { [weak self] _ in self?.pool.releaseAll() }
    }

    /// Acquires a `VideoRenderer` from the pool with the specified size.
    ///
    /// - Parameter size: The desired size for the acquired `VideoRenderer`.
    /// - Returns: A `VideoRenderer` instance from the pool.
    @MainActor
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

    /// Configures the global video renderer pool with the specified initial capacity.
    /// This method is intended for internal use by StreamVideo.
    ///
    /// - Parameter initialCapacity: The number of video renderers to pre-create.
    @MainActor
    static func configure(initialCapacity: Int) async {
        // Create pool with 0 initial capacity first
        currentValue = VideoRendererPool(initialCapacity: 0)
        
        // Then add renderers one by one with yielding
        for _ in 0..<initialCapacity {
            let renderer = VideoRenderer(frame: CGRect(origin: .zero, size: .zero))
            currentValue.pool.addToAvailable(renderer)
            
            // Yield to allow other main thread work between renderer creations
            await Task.yield()
        }
    }
}

/// - Note: I have no other way of satisfying the compiler here.
#if compiler(>=6.0)
extension VideoRendererPool: @preconcurrency InjectionKey {
    @MainActor
    static var currentValue: VideoRendererPool = .init()
}
#else
extension VideoRendererPool: InjectionKey {
    @MainActor
    static var currentValue: VideoRendererPool = .init()
}
#endif

extension InjectedValues {
    var videoRendererPool: VideoRendererPool {
        get { Self[VideoRendererPool.self] }
        set { _ = newValue }
    }
}
