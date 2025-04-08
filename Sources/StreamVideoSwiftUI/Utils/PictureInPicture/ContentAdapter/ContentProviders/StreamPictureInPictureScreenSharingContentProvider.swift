//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

final class StreamPictureInPictureScreenSharingContentProvider: NSObject, StreamPictureInPictureContentProvider,
    @unchecked Sendable {

    private struct State {
        var track: RTCVideoTrack
        var participant: CallParticipant
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
            case let .screenSharing(participant, track):
                if state?.track.trackId != track.trackId {
                    state?.track.remove(self)
                    try? await Task.sleep(nanoseconds: 250 * 1_000_000)
                    track.add(self)
                    frameProcessor.reset()

                    self.state = .init(
                        track: track,
                        participant: participant
                    )
                } else {
                    /* No-op */
                }
            default:
                state?.track.remove(self)
                state = nil
            }
        }
    }
}

extension StreamPictureInPictureScreenSharingContentProvider: RTCVideoRenderer {

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
