//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

final class StreamPictureInPictureStaticContentProvider: NSObject, StreamPictureInPictureContentProvider, @unchecked Sendable {

    @Injected(\.pictureInPictureViewFactory) private var pictureInPictureViewFactory

    private struct State {
        var participant: CallParticipant
    }

    private let dataPipeline: PictureInPictureDataPipeline
    private let serialQueue = SerialActorQueue()

    private var state: State?
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
            case let .static(participant):
                if state?.participant.sessionId != participant.sessionId {
                    self.state = .init(
                        participant: participant
                    )
                    frameGenerator.isActive = true
                    log.debug(
                        "Static frame generator is now active for participant:\(participant.name).",
                        subsystems: .pictureInPicture
                    )
                } else {
                    /* No-op */
                }
            default:
                frameGenerator.isActive = false
                state = nil
            }
        }
    }

    // MARK: - Private Helpers

    private func buildFrameGenerator() -> StreamPictureInPictureStaticFrameProvider {
        let result = StreamPictureInPictureStaticFrameProvider(dataPipeline: dataPipeline) { [weak self] size in
            await .build(size: size) { [weak self] in
                if let self, let state = self.state {
                    if #available(iOS 14.0, *) {
                        GenericCallParticipantImageView(
                            viewFactory: pictureInPictureViewFactory,
                            id: state.participant.id,
                            name: state.participant.name,
                            imageURL: state.participant.profileImageURL ?? state.participant.user.imageURL,
                            size: size.width / 4
                        )
                        .ignoresSafeArea()
                    } else {
                        GenericCallParticipantImageView(
                            viewFactory: pictureInPictureViewFactory,
                            id: state.participant.id,
                            name: state.participant.name,
                            imageURL: state.participant.profileImageURL ?? state.participant.user.imageURL,
                            size: size.width / 4
                        )
                    }
                } else {
                    EmptyView()
                }
            }
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
