//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

final class FileScreenCapturer: RTCVideoCapturer, @unchecked Sendable {
    private let source: RTCVideoCapturerDelegate
    private let audioDeviceModule: AudioDeviceModule
    private let reader: AVAssetReader?
    private let videoOutputReader: VideoOutputReader
    private let audioOutputReader: AudioOutputReader
    private var captureTask: Task<Void, Never>?

    init(
        source: RTCVideoCapturerDelegate,
        audioDeviceModule: AudioDeviceModule,
        fileURL: URL
    ) {
        self.source = source
        self.audioDeviceModule = audioDeviceModule
        self.reader = try? .init(asset: .init(url: fileURL))
        self.videoOutputReader = .init(source)
        self.audioOutputReader = .init(audioDeviceModule)
        super.init()
    }

    func startCapturing() {
        guard
            let reader,
            reader.status != .reading
        else {
            log.error(ClientError())
            return
        }

        videoOutputReader.prepareToStart(with: reader)
        audioOutputReader.prepareToStart(with: reader)

        guard reader.startReading() else {
            stopCapturing()
            return
        }

        captureTask?.cancel()
        captureTask = Task.detached(priority: .userInitiated) { [weak self] in
            await self?.runCaptureLoop()
        }
    }

    func stopCapturing() {
        captureTask?.cancel()
        captureTask = nil
        videoOutputReader.stop()
        audioOutputReader.stop()
        reader?.cancelReading()
    }

    // MARK: - Private Helpers

    private func runCaptureLoop() async {
        var basePTS: CMTime?
        let startHostTime = CMClockGetTime(CMClockGetHostTimeClock())

        var nextVideo = videoOutputReader.copyNextSampleBuffer()
        var nextAudio = audioOutputReader.copyNextSampleBuffer()

        while !Task.isCancelled, nextVideo != nil || nextAudio != nil {
            let (buffer, isVideo) = Self.earliestBuffer(nextVideo, nextAudio)

            guard let buffer else {
                break
            }

            let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
            if basePTS == nil {
                basePTS = pts
            }

            let relative = pts - (basePTS ?? .zero)
            let targetHost = startHostTime + relative
            let now = CMClockGetTime(CMClockGetHostTimeClock())
            let delay = max(0, CMTimeGetSeconds(targetHost - now))

            if delay > 0 {
                try? await Task.sleep(
                    nanoseconds: UInt64(delay * 1_000_000_000)
                )
            }

            if Task.isCancelled {
                break
            }

            if isVideo {
                videoOutputReader.consume(buffer)
                nextVideo = videoOutputReader.copyNextSampleBuffer()
            } else {
                audioOutputReader.consume(buffer)
                nextAudio = audioOutputReader.copyNextSampleBuffer()
            }
        }
    }

    private static func earliestBuffer(
        _ video: CMSampleBuffer?,
        _ audio: CMSampleBuffer?
    ) -> (CMSampleBuffer?, Bool) {
        switch (video, audio) {
        case (nil, nil):
            return (nil, false)
        case (let video?, nil):
            return (video, true)
        case (nil, let audio?):
            return (audio, false)
        case (let video?, let audio?):
            let videoPTS = CMSampleBufferGetPresentationTimeStamp(video)
            let audioPTS = CMSampleBufferGetPresentationTimeStamp(audio)
            return (videoPTS <= audioPTS ? video : audio, videoPTS <= audioPTS)
        }
    }
}
