//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// A builder class that simplifies the creation and management of
/// `AVAudioRecorder` instances for audio recording.
///
/// This builder provides:
/// - **Caching**: Stores created `AVAudioRecorder` objects for efficient
///   reuse, avoiding redundant initialization
/// - **Customizable settings**: Allows you to tailor recording parameters
///   to your specific needs
///
/// ## Usage
/// ```swift
/// let builder = AVAudioRecorderBuilder()
/// try builder.build()
/// let recorder = builder.result
/// ```
///
/// - Important: You must call ``build()`` before trying to access the
///   ``result`` property.
final class AVAudioRecorderBuilder {

    /// Default recording settings optimized for voice recording.
    ///
    /// Uses `kAudioFormatLinearPCM` to support multiple simultaneous
    /// `AVAudioRecorder` instances (useful when using `MicrophoneChecker`
    /// during a call).
    ///
    /// - Note: See https://stackoverflow.com/a/8575101 for more details
    ///   about PCM format compatibility.
    static let defaultRecordingSettings: [String: any Sendable] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    /// The URL where the audio recording will be saved.
    ///
    /// This is typically a location in the app's cache directory.
    let fileURL: URL

    /// A dictionary containing audio recording configurations.
    ///
    /// Includes settings for:
    /// - Audio format (e.g., PCM)
    /// - Sample rate (Hz)
    /// - Number of channels (mono/stereo)
    /// - Audio quality
    let settings: [String: Any]

    private let queue = UnfairQueue()
    
    /// A property storing the built `AVAudioRecorder` instance.
    ///
    /// This value is populated after calling ``build()`` and cached for
    /// subsequent access.
    private var cachedResult: AVAudioRecorder?

    /// The built `AVAudioRecorder` instance, if available.
    ///
    /// Returns `nil` if ``build()`` has not been called yet or if building
    /// failed.
    var result: AVAudioRecorder? { cachedResult }

    /// Initializes a new audio recorder builder with the specified filename
    /// and settings.
    ///
    /// - Parameters:
    ///   - filename: The name of the file to save recordings to.
    ///     Defaults to "recording.wav".
    ///   - settings: The audio recording settings to use.
    ///     Defaults to ``defaultRecordingSettings``.
    init(
        inCacheDirectoryWithFilename filename: String = "recording.wav",
        settings: [String: any Sendable] = AVAudioRecorderBuilder.defaultRecordingSettings
    ) {
        let documentPath = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
        fileURL = documentPath.appendingPathComponent(filename)
        self.settings = settings
    }

    /// Initializes a builder with an existing `AVAudioRecorder` instance.
    ///
    /// This initializer is useful for wrapping an already-configured
    /// recorder.
    ///
    /// - Parameter cachedResult: An existing `AVAudioRecorder` instance
    ///   to use.
    init(
        cachedResult: AVAudioRecorder
    ) {
        self.cachedResult = cachedResult
        fileURL = cachedResult.url
        settings = cachedResult.settings
    }

    /// Builds and caches an `AVAudioRecorder` instance.
    ///
    /// This method creates a new `AVAudioRecorder` with the configured
    /// settings and file URL. If a recorder has already been built, this
    /// method does nothing.
    ///
    /// - Throws: An error if the `AVAudioRecorder` initialization fails.
    ///
    /// - Note: This method is thread-safe and ensures only one recorder
    ///   instance is created.
    func build() throws {
        try queue.sync {
            if cachedResult == nil {
                let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
                self.cachedResult = audioRecorder
            }
        }
    }
}
