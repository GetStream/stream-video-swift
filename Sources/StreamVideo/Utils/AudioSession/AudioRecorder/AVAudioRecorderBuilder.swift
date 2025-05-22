//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// The AVAudioRecorderBuilder actor simplifies the creation and management of AVAudioRecorder
/// instances for audio recording. It offers:
/// Caching: Stores created AVAudioRecorder objects for efficient reuse, avoiding redundant initialization.
/// Customisable settings: Allows you to tailor recording parameters to your specific needs.
///
/// - Important: You need to call `.build()` before trying to access the `result` property.
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

    /// The URL where the audio recording will be saved.
    let fileURL: URL

    /// A dictionary containing audio format, sample rate, number of channels, and quality configurations.
    let settings: [String: Any]

    /// A property storing the built AVAudioRecorder instance.
    private var cachedResult: AVAudioRecorder?

    var result: AVAudioRecorder? { cachedResult }

    init(
        inCacheDirectoryWithFilename filename: String,
        settings: [String: any Sendable] = AVAudioRecorderBuilder.defaultRecordingSettings
    ) {
        let documentPath = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
        fileURL = documentPath.appendingPathComponent(filename)
        self.settings = settings
    }

    init(
        cachedResult: AVAudioRecorder
    ) {
        self.cachedResult = cachedResult
        fileURL = cachedResult.url
        settings = cachedResult.settings
    }

    /// Instructs the `AVAudioRecorderBuilder` to build and cache an instance of AVAudioRecorder.
    func build() throws {
        guard cachedResult == nil else { return }
        let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        cachedResult = audioRecorder
    }
}
