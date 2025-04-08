//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

final class StreamPictureInPictureReconnectingContentProvider: NSObject, StreamPictureInPictureContentProvider,
    @unchecked Sendable {

    @Injected(\.pictureInPictureViewFactory) private var pictureInPictureViewFactory

    private let dataPipeline: PictureInPictureDataPipeline
    private let serialQueue = SerialActorQueue()

    private var contentSizeCancellable: AnyCancellable?

    private lazy var frameGenerator = buildFrameGenerator()

    weak var call: Call?

    init(dataPipeline: PictureInPictureDataPipeline) {
        self.dataPipeline = dataPipeline
        super.init()
        _ = frameGenerator
    }

    // MARK: - StreamPictureInPictureContentProvider

    func process(_ content: PictureInPictureDataPipeline.Content) {
        serialQueue.async { [weak self] in
            guard let self else {
                return
            }

            switch content {
            case .reconnecting:
                if frameGenerator.isActive == false {
                    frameGenerator.isActive = true
                    log.debug(
                        "Reconnecting frame generator is now active.",
                        subsystems: .pictureInPicture
                    )
                } else {
                    /* No-op */
                }
            default:
                frameGenerator.isActive = false
            }
        }
    }

    // MARK: - Private Helpers

    private func buildFrameGenerator() -> StreamPictureInPictureStaticFrameProvider {
        let result = StreamPictureInPictureStaticFrameProvider(dataPipeline: dataPipeline) {
            await .build(size: $0) { ReconnectingView() }
        }

        contentSizeCancellable = dataPipeline
            .sizeEventPublisher
            .compactMap {
                switch $0 {
                case let .contentSizeUpdated(size):
                    return size
                default:
                    return nil
                }
            }
            .assign(to: \.contentSize, on: result)

        return result
    }
}
