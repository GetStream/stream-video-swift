//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import Foundation
import StreamVideo
import StreamWebRTC

final class StreamPictureInPictureParticipantContentProvider: NSObject, StreamPictureInPictureContentProvider, @unchecked Sendable {

    private struct State {
        var track: RTCVideoTrack
        var participant: CallParticipant
        var sizeCancellable: AnyCancellable
    }

    private let dataPipeline: PictureInPictureDataPipeline
    private let frameProcessor: StreamPictureInPictureFrameProcessor
    private let serialQueue = SerialActorQueue()

    private var state: State?

    weak var call: Call?

    init(dataPipeline: PictureInPictureDataPipeline) {
        self.dataPipeline = dataPipeline
        frameProcessor = .init(dataPipeline: dataPipeline)
    }

    // MARK: - StreamPictureInPictureContentProvider

    func process(_ content: PictureInPictureDataPipeline.Content) {
        serialQueue.async { [weak self] in
            guard let self else {
                return
            }

            switch content {
            case let .participant(participant, track):
                if state?.track.trackId != track.trackId {
                    state?.sizeCancellable.cancel()
                    state?.track.remove(self)
                    track.add(self)
                    frameProcessor.reset()
                    let cancellable = dataPipeline
                        .sizeEventPublisher
                        .compactMap {
                            switch $0 {
                            case let .contentSizeUpdated(size):
                                return size
                            default:
                                return nil
                            }
                        }
                        .sinkTask { [weak call] in await call?.updateTrackSize($0, for: participant) }
                    self.state = .init(
                        track: track,
                        participant: participant,
                        sizeCancellable: cancellable
                    )
                } else {
                    /* No-op */
                }
            default:
                state?.sizeCancellable.cancel()
                state?.track.remove(self)
                frameProcessor.reset()
                state = nil
            }
        }
    }
}

extension StreamPictureInPictureParticipantContentProvider: RTCVideoRenderer {

    func setSize(_ size: CGSize) {
        dataPipeline.setPreferredSize(size)
    }

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let buffer = frameProcessor.process(frame)?.buffer else {
            return
        }

        dataPipeline.send(buffer)
    }
}
