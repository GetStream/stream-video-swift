//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

actor AVAudioRecorderBuilder {

    // `kAudioFormatLinearPCM` is being used to be able to support multiple
    // instances of AVAudioRecorders. (useful when using MicrophoneChecker
    // during a Call).
    // https://stackoverflow.com/a/8575101
    static let defaultRecordingSettings: [String: any Sendable] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    let fileURL: URL
    let settings: [String: Any]

    private var cachedResult: AVAudioRecorder?
    private var factory: (URL, [String: Any]) throws -> AVAudioRecorder = {
        try .init(url: $0, settings: $1)
    }

    var result: AVAudioRecorder? { cachedResult }

    init(
        inCacheDirectoryWithFilename filename: String,
        settings: [String: any Sendable] = AVAudioRecorderBuilder.defaultRecordingSettings
    ) {
        let documentPath = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
        self.fileURL = documentPath.appendingPathComponent(filename)
        self.settings = settings
    }

    init(
        cachedResult: AVAudioRecorder
    ) {
        self.cachedResult = cachedResult
        self.fileURL = cachedResult.url
        self.settings = cachedResult.settings
    }

    func build() throws {
        guard cachedResult == nil else { return }
        let audioRecorder = try factory(fileURL, settings)
        self.cachedResult = audioRecorder
    }
}

extension AVAudioRecorder: @unchecked Sendable {}
