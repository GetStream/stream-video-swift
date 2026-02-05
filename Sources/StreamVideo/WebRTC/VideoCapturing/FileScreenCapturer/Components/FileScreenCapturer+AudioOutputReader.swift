//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension FileScreenCapturer {
    final class AudioOutputReader: @unchecked Sendable {

        private enum State: Equatable {
            case idle

            case running(
                audioTrackOutput: AVAssetReaderTrackOutput,
                basePTS: CMTime?,
                startHostTime: CMTime
            )

            static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.idle, .idle):
                    return true
                case (let .running(lvto, lBasePTS, lStartHostTime), let .running(rvto, rBasePTS, rStartHostTime)):
                    return lvto == rvto
                        && lBasePTS == rBasePTS
                        && lStartHostTime == rStartHostTime
                default:
                    return false
                }
            }
        }

        private let source: AudioDeviceModule
        private let queue = OperationQueue(maxConcurrentOperationCount: 1)

        private var state: State = .idle

        init(_ source: AudioDeviceModule) {
            self.source = source
        }

        func start(with assetReader: AVAssetReader) {
            queue.addOperation { [weak self] in
                guard
                    let self,
                    state == .idle,
                    let track = assetReader.asset.tracks(withMediaType: .audio).first
                else {
                    return
                }

                let trackOutput = configureTrackOutput(
                    assetReader: assetReader,
                    track: track
                )

                state = .running(
                    audioTrackOutput: trackOutput,
                    basePTS: nil,
                    startHostTime: CMClockGetTime(CMClockGetHostTimeClock())
                )

                readNext()
            }
        }

        func stop() {
            queue.addOperation { [weak self] in
                guard let self else { return }

                switch state {
                case .idle:
                    break

                case .running:
                    state = .idle
                }
            }
        }

        // MARK: - Private Helpers

        private func configureTrackOutput(
            assetReader: AVAssetReader,
            track: AVAssetTrack
        ) -> AVAssetReaderTrackOutput {
            let trackOutput = AVAssetReaderTrackOutput(
                track: track,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMIsFloatKey: true,
                    AVLinearPCMBitDepthKey: 32,
                    AVLinearPCMIsNonInterleaved: false,
                    AVSampleRateKey: 48000,
                    AVNumberOfChannelsKey: 2
                ]
            )

            assetReader.add(trackOutput)

            return trackOutput
        }

        private func readNext() {
            queue.addTaskOperation { [weak self] in
                guard
                    let self,
                    case var .running(
                        trackOutput,
                        basePTS,
                        startHostTime
                    ) = state
                else {
                    return
                }

                guard
                    let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                    CMSampleBufferIsValid(sampleBuffer)
                else {
                    state = .idle
                    return
                }

                let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                if basePTS == nil {
                    basePTS = pts
                }

                state = .running(
                    audioTrackOutput: trackOutput,
                    basePTS: basePTS,
                    startHostTime: startHostTime
                )

                let relative = pts - (basePTS ?? .zero)
                let targetHost = startHostTime + relative
                let now = CMClockGetTime(CMClockGetHostTimeClock())
                let delay = max(0, CMTimeGetSeconds(targetHost - now))

                if delay > 0 {
                    try? await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                }

                guard case .running = state else {
                    return
                }

                source.enqueue(sampleBuffer)

                readNext()
            }
        }
    }
}
