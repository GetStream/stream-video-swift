//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

final class VideoRendererPool {

    private let initialCapacity: Int
    private let queue = UnfairQueue()
    private var available: [VideoRenderer] = []
    private var inUse: Set<VideoRenderer> = []
    private var callEndedCancellable: AnyCancellable?

    init(initialCapacity: Int = 10) {
        self.initialCapacity = initialCapacity

        // Initialize the pool with a set number of renderers
        for _ in 0..<initialCapacity {
            let renderer = VideoRenderer(frame: .zero)
            available.append(renderer)
        }

        callEndedCancellable = NotificationCenter
            .default
            .publisher(for: Notification.Name(CallNotification.callEnded))
            .sink { [weak self] _ in self?.releaseAll() }
    }

    func acquireRenderer(size: CGSize) -> VideoRenderer {
        var renderer: VideoRenderer!

        queue.sync {
            if let available = available.popLast() {
                renderer = available
                inUse.insert(available)
                log.debug("Reusing VideoRenderer:\(String(describing: renderer)).")
            } else {
                renderer = VideoRenderer(frame: .init(origin: .zero, size: size))
                inUse.insert(renderer)
                log.debug("Created new VideoRenderer:\(String(describing: renderer)).")
            }
        }

        renderer.frame.size = size
        return renderer
    }

    func releaseRenderer(_ renderer: VideoRenderer) {
        queue.sync {
            if inUse.contains(renderer), available.endIndex < initialCapacity {
                inUse.remove(renderer)
                available.append(renderer)
                log.debug("Will make available VideoRenderer:\(renderer).")
            } else {
                inUse.remove(renderer)
                log.debug("Will release VideoRenderer:\(renderer).")
            }
        }
    }

    private func releaseAll() {
        queue.sync {
            for renderer in inUse {
                guard available.endIndex < initialCapacity else {
                    return
                }
                inUse.remove(renderer)
                available.append(renderer)
                log.debug("Will make available VideoRenderer:\(renderer).")
            }
            if !inUse.isEmpty {
                log.debug("Will release \(inUse.count) VideoRenderer instances.")
                inUse.removeAll()
            }
        }
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
