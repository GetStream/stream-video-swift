//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Convenience extensions for `AVAudioRecorder` to simplify audio recording
/// setup.
extension AVAudioRecorder {

    /// Creates a new audio recorder with default settings optimized for voice
    /// recording.
    ///
    /// This convenience method simplifies recorder creation by:
    /// - Automatically selecting the app's cache directory for storage
    /// - Providing sensible default recording settings for voice
    /// - Handling file URL construction
    ///
    /// ## Default Settings
    ///
    /// The default settings are optimized for voice recording:
    /// - **Format**: Linear PCM (uncompressed, highest quality)
    /// - **Sample Rate**: 12 kHz (suitable for voice)
    /// - **Channels**: Mono (single channel)
    /// - **Quality**: High
    ///
    /// ## File Storage
    ///
    /// Audio files are stored in the app's cache directory, which:
    /// - Doesn't require user permission
    /// - Is automatically managed by iOS
    /// - Can be cleared when device storage is low
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // Create recorder with default settings
    /// let recorder = try AVAudioRecorder.build()
    ///
    /// // Create recorder with custom filename
    /// let customRecorder = try AVAudioRecorder.build(
    ///     filename: "interview.wav"
    /// )
    ///
    /// // Create recorder with custom settings
    /// let highQualityRecorder = try AVAudioRecorder.build(
    ///     filename: "music.wav",
    ///     settings: [
    ///         AVFormatIDKey: Int(kAudioFormatLinearPCM),
    ///         AVSampleRateKey: 44100,
    ///         AVNumberOfChannelsKey: 2,
    ///         AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
    ///     ]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - filename: The name of the audio file to create. Defaults to
    ///     "recording.wav". The file will be stored in the app's cache
    ///     directory.
    ///   - settings: Dictionary of audio recording settings. Defaults to
    ///     settings optimized for voice recording. See `AVAudioRecorder`
    ///     documentation for available keys.
    ///
    /// - Returns: A configured `AVAudioRecorder` instance ready for
    ///   recording.
    ///
    /// - Throws: An error if the recorder cannot be initialized, typically
    ///   due to:
    ///   - Invalid recording settings
    ///   - File system errors
    ///   - Audio session configuration issues
    ///
    /// - Note: Remember to configure the audio session and request microphone
    ///   permission before attempting to record.
    ///
    /// - Important: Linear PCM format is used by default to support multiple
    ///   simultaneous `AVAudioRecorder` instances. Compressed formats may
    ///   limit you to a single recorder at a time.
    static func build(
        filename: String = "recording.wav",
        settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    ) throws -> AVAudioRecorder {
        // Get the cache directory for temporary audio storage
        guard
            let documentPath = FileManager.default.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            ).first
        else {
            throw ClientError("No cache directory available.")
        }

        // Construct the full file URL
        let fileURL = documentPath.appendingPathComponent(filename)
        
        // Create and return the configured recorder
        return try .init(url: fileURL, settings: settings)
    }
}
