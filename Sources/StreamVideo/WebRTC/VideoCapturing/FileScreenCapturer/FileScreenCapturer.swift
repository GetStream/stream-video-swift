//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class FileScreenCapturer: RTCVideoCapturer {
    private let source: RTCVideoCapturerDelegate
    private let audioDeviceModule: AudioDeviceModule
    private let reader: AVAssetReader?
    private let videoOutputReader: VideoOutputReader
    private let audioOutputReader: AudioOutputReader

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
            reader.startReading()
        else {
            log.error(ClientError())
            return
        }

        videoOutputReader.start(with: reader)
        audioOutputReader.start(with: reader)
    }

    func stopCapturing() {
        videoOutputReader.stop()
        audioOutputReader.stop()
        reader?.cancelReading()
    }
}
