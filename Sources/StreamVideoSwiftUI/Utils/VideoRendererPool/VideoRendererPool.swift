//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

final class VideoRendererPool {

    private let pool: ReusePool<VideoRenderer>
    private var callEndedCancellable: AnyCancellable?

    init(initialCapacity: Int = 10) {
        pool = .init(initialCapacity: initialCapacity) {
            VideoRenderer(frame: .init(origin: .zero, size: .zero))
        }

        callEndedCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .sink { [weak self] _ in self?.pool.releaseAll() }
    }

    func acquireRenderer(size: CGSize) -> VideoRenderer {
        let renderer = pool.acquire()
        renderer.frame.size = size
        return renderer
    }

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
