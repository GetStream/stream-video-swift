//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// A high-level audio recorder for managing audio recording during calls.
///
/// This class provides a simplified interface for audio recording,
/// abstracting the complexity of `AVAudioRecorder` management and audio
/// session configuration. It automatically handles:
/// - Recording permissions
/// - Audio session category management
/// - Interruption handling
/// - Active call synchronization
/// - Real-time audio level monitoring
///
/// ## Usage Example
///
/// ```swift
/// let recorder = StreamCallAudioRecorder()
///
/// // Subscribe to audio levels
/// recorder.metersPublisher.sink { level in
///     print("Audio level: \(level) dB")
/// }
///
/// // Start recording
/// await recorder.startRecording()
///
/// // Stop recording
/// await recorder.stopRecording()
/// ```
///
/// ## Automatic Behavior
///
/// By default, the recorder synchronizes with the active call state:
/// - Starts recording when the user enables their microphone in a call
/// - Stops recording when the call ends or microphone is disabled
/// - Handles interruptions gracefully (phone calls, alarms, etc.)
open class StreamCallAudioRecorder: @unchecked Sendable {
    /// The internal store managing recording state.
    private let store = Namespace.store(initialState: .initial)

    /// Publisher that emits real-time audio power levels during recording.
    ///
    /// The published values represent the average power in decibels (dB),
    /// typically ranging from -160 dB (silence) to 0 dB (maximum level).
    /// Updates are published at the display refresh rate for smooth UI
    /// updates.
    ///
    /// ## Example
    ///
    /// ```swift
    /// recorder.metersPublisher
    ///     .map { dB in
    ///         // Convert dB to normalized value (0...1)
    ///         return (dB + 160) / 160
    ///     }
    ///     .sink { normalizedLevel in
    ///         updateWaveformUI(level: normalizedLevel)
    ///     }
    /// ```
    open private(set) lazy var metersPublisher: AnyPublisher<Float, Never> = store
        .publisher(\.meter)

    /// Initializes a new audio recorder instance.
    ///
    /// The recorder is initialized with default settings optimized for
    /// voice recording during calls.
    public init() {}

    // MARK: - Public API

    /// Starts audio recording asynchronously.
    ///
    /// This method initiates audio recording if permissions are granted
    /// and the audio session is properly configured. Recording will
    /// automatically stop if an interruption occurs or permissions are
    /// revoked.
    ///
    /// - Parameter ignoreActiveCall: When `true`, starts recording
    ///   regardless of whether there's an active call. When `false`
    ///   (default), recording only starts if there's an active call with
    ///   audio enabled. This is useful for testing audio levels outside
    ///   of a call context.
    ///
    /// - Note: Recording requires microphone permission. The system will
    ///   prompt for permission if not already granted.
    open func startRecording(ignoreActiveCall: Bool = false) async {
        if ignoreActiveCall {
            store.dispatch(.setShouldRecord(true))
        }

        store.dispatch(.setIsRecording(true))
    }

    /// Stops audio recording asynchronously.
    ///
    /// This method stops the current recording session and releases
    /// associated resources. Audio level updates will cease after calling
    /// this method.
    ///
    /// - Note: This method is safe to call even if recording is not
    ///   currently active.
    open func stopRecording() async {
        store.dispatch(.setIsRecording(false))
    }
}

/// Injection key for providing the default `StreamCallAudioRecorder`
/// instance.
///
/// This key enables dependency injection of the audio recorder throughout
/// the application.
struct StreamCallAudioRecorderKey: InjectionKey {
    /// The default recorder instance used when no custom recorder is
    /// provided.
    nonisolated(unsafe) static var currentValue: StreamCallAudioRecorder = StreamCallAudioRecorder()
}

extension InjectedValues {
    /// The shared audio recorder instance for call audio recording.
    ///
    /// This property provides access to the application-wide audio recorder
    /// through dependency injection. You can customize the recorder by
    /// setting a custom instance:
    ///
    /// ```swift
    /// // Use a custom recorder
    /// InjectedValues[\Self.callAudioRecorder] = CustomAudioRecorder()
    /// ```
    public var callAudioRecorder: StreamCallAudioRecorder {
        get {
            Self[StreamCallAudioRecorderKey.self]
        }
        set {
            Self[StreamCallAudioRecorderKey.self] = newValue
        }
    }
}
