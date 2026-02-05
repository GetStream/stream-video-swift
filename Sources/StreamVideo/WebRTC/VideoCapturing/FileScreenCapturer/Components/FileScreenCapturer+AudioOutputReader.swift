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
                audioTrackOutput: AVAssetReaderTrackOutput
            )

            static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.idle, .idle):
                    return true
                case (let .running(lvto), let .running(rvto)):
                    return lvto == rvto
                default:
                    return false
                }
            }
        }

        private let source: AudioDeviceModule

        @Atomic private var state: State = .idle

        init(_ source: AudioDeviceModule) {
            self.source = source
        }

        func prepareToStart(with assetReader: AVAssetReader) {
            guard
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
                audioTrackOutput: trackOutput
            )
        }

        func stop() {
            state = .idle
        }

        func copyNextSampleBuffer() -> CMSampleBuffer? {
            guard case let .running(trackOutput) = state else {
                return nil
            }

            return trackOutput.copyNextSampleBuffer()
        }

        func consume(_ sampleBuffer: CMSampleBuffer) {
            guard CMSampleBufferIsValid(sampleBuffer) else {
                return
            }

            source.enqueue(sampleBuffer)
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
    }
}
