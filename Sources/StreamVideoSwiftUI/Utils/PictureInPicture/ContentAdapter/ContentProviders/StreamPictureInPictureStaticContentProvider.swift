//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

final class StreamPictureInPictureStaticContentProvider: NSObject, StreamPictureInPictureContentProvider,
    @unchecked Sendable {

    private struct State {
        var participant: CallParticipant
    }

    private let dataPipeline: PictureInPictureDataPipeline
    private let frameGenerator: StaticFrameProvider
    private let serialQueue = SerialActorQueue()

    private var state: State?
    private var contentSizeCancellable: AnyCancellable?

    weak var call: Call?

    init(dataPipeline: PictureInPictureDataPipeline) {
        self.dataPipeline = dataPipeline
        self.frameGenerator = .init(dataPipeline: dataPipeline) {
            await .build(size: $0) { Color.red }
        }

        contentSizeCancellable = dataPipeline
            .sizeEventPublisher
            .compactMap {
                switch $0 {
                case .contentSizeUpdated(let size):
                    return size
                default:
                    return nil
                }
            }
            .assign(to: \.contentSize, on: frameGenerator)

    }

    // MARK: - StreamPictureInPictureContentProvider

    func process(_ content: PictureInPictureDataPipeline.Content) {
        serialQueue.async { [weak self] in
            guard let self else {
                return
            }

            switch content {
            case let .static(participant):
                if state?.participant.sessionId != participant.sessionId {
                    self.state = .init(
                        participant: participant
                    )
                    frameGenerator.isActive = true
                } else {
                    /* No-op */
                }
            default:
                frameGenerator.isActive = false
                state = nil
            }
        }
    }
}

private final class StaticFrameProvider: @unchecked Sendable {

    var contentSize: CGSize = .zero {
        didSet { cachedFrameAccessQueue.sync { cache = nil } }
    }

    var isActive: Bool = false {
        willSet {
            if newValue, generationCancellable == nil {
                generationCancellable = Timer
                    .publish(every: interval, on: .main, in: .default)
                    .autoconnect()
                    .sinkTask { @MainActor [weak self] _ in await self?.generateFrame() }
            } else if !newValue {
                generationCancellable?.cancel()
            }
        }
    }

    private let interval: TimeInterval
    private let provider: (CGSize) async -> CVPixelBuffer?
    private let dataPipeline: PictureInPictureDataPipeline

    private let cachedFrameAccessQueue = UnfairQueue()
    private var cache: CVPixelBuffer?
    private var generationCancellable: AnyCancellable?

    init(
        fps: Int = 15,
        dataPipeline: PictureInPictureDataPipeline,
        provider: @escaping (CGSize) async -> CVPixelBuffer?
    ) {
        self.interval = 1 / 15
        self.dataPipeline = dataPipeline
        self.provider = provider
    }

    private func generateFrame() async {
        if let cache = cachedFrameAccessQueue.sync({ cache })?.sampleBuffer {
            dataPipeline.send(cache)
        } else {
            if let frame = await provider(contentSize)?.sampleBuffer {
//                cachedFrameAccessQueue.sync { cache = frame }
                dataPipeline.send(frame)
            } else {
                log.warning("⚠️ Failed to generate static frame.", subsystems: .pictureInPicture)
            }
        }
    }
}
