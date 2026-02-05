//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension FileScreenCapturer {
    final class VideoOutputReader: RTCVideoCapturer, @unchecked Sendable {

        private enum State: Equatable {
            case idle
            case running(videoTrackOutput: AVAssetReaderTrackOutput)
        }

        private weak var source: RTCVideoCapturerDelegate?

        @Atomic private var state: State = .idle

        init(_ source: RTCVideoCapturerDelegate) {
            self.source = source
            super.init()
        }

        func prepareToStart(with assetReader: AVAssetReader) {
            guard
                state == .idle,
                let track = assetReader.asset.tracks(withMediaType: .video).first
            else {
                return
            }

            let videoTrackOutput = configureVideoTrackOutput(
                assetReader: assetReader,
                track: track
            )

            state = .running(videoTrackOutput: videoTrackOutput)
        }

        func stop() {
            state = .idle
        }

        func copyNextSampleBuffer() -> CMSampleBuffer? {
            guard case let .running(videoTrackOutput) = state else {
                return nil
            }

            return videoTrackOutput.copyNextSampleBuffer()
        }

        func consume(_ sampleBuffer: CMSampleBuffer) {
            guard
                CMSampleBufferIsValid(sampleBuffer),
                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else {
                return
            }

            let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let videoFrame = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)

            let rtcVideoFrame = RTCVideoFrame(
                buffer: videoFrame,
                rotation: ._0,
                timeStampNs: Int64(CMTimeGetSeconds(frameTime) * 1e9)
            )

            source?.capturer(self, didCapture: rtcVideoFrame)
        }

        // MARK: - Private Helpers

        private func configureVideoTrackOutput(
            assetReader: AVAssetReader,
            track: AVAssetTrack
        ) -> AVAssetReaderTrackOutput {
            let videoTrackOutput = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [
                    kCVPixelBufferPixelFormatTypeKey as String: NSNumber(
                        value: kCVPixelFormatType_32BGRA
                    )
                ]
            )

            assetReader.add(videoTrackOutput)

            return videoTrackOutput
        }
    }
}
