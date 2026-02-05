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

            case running(
                displayLink: CADisplayLink,
                videoTrackOutput: AVAssetReaderTrackOutput
            )

            static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.idle, .idle):
                    return true
                case (let .running(ldl, lvto), let .running(rdl, rvto)):
                    return ldl === rdl && lvto == rvto
                default:
                    return false
                }
            }
        }

        private weak var source: RTCVideoCapturerDelegate?
        private let queue = OperationQueue(maxConcurrentOperationCount: 1)

        private var state: State = .idle

        init(_ source: RTCVideoCapturerDelegate) {
            self.source = source
            super.init()
        }

        func start(with assetReader: AVAssetReader) {
            queue.addOperation { [weak self] in
                guard
                    let self,
                    state == .idle,
                    let track = assetReader.asset.tracks(withMediaType: .video).first
                else {
                    return
                }
                do {
                    let videoTrackOutput = configureVideoTrackOutput(
                        assetReader: assetReader,
                        track: track
                    )
                    let displayLink = configureDisplayLink()

                    state = .running(
                        displayLink: displayLink,
                        videoTrackOutput: videoTrackOutput
                    )
                } catch {
                    log.error(error)
                }
            }
        }

        func stop() {
            queue.addOperation { [weak self] in
                guard let self else { return }

                switch state {
                case .idle:
                    break

                case let .running(displayLink, _):
                    displayLink.invalidate()
                    state = .idle
                }
            }
        }

        // MARK: - Private Helpers

        private func configureVideoTrackOutput(
            assetReader: AVAssetReader,
            track: AVAssetTrack
        ) -> AVAssetReaderTrackOutput {
            let videoTrackOutput = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [
                    kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
                ]
            )

            assetReader.add(videoTrackOutput)

            return videoTrackOutput
        }

        private func configureDisplayLink() -> CADisplayLink {
            let displayLink = CADisplayLink(
                target: self,
                selector: #selector(self.readFrame)
            )
            displayLink.preferredFramesPerSecond = 30 // Assuming 30 fps video
            displayLink.add(to: .main, forMode: .common)

            return displayLink
        }

        @objc
        private func readFrame() {
            queue.addOperation { [weak self] in
                guard
                    let self,
                    case let .running(_, videoTrackOutput) = state,
                    let sampleBuffer = videoTrackOutput.copyNextSampleBuffer(),
                    CMSampleBufferIsValid(sampleBuffer)
                else {
                    return
                }

                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
                let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let videoFrame = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)

                let rtcVideoFrame = RTCVideoFrame(
                    buffer: videoFrame,
                    rotation: ._0,
                    timeStampNs: Int64(CMTimeGetSeconds(frameTime) * 1e9)
                )

                source?.capturer(self, didCapture: rtcVideoFrame)
            }
        }
    }
}
