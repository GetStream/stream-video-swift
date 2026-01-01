//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    /// The current audio power level in decibels (dB).
    ///
    /// This property is continuously updated during recording to reflect
    /// the real-time audio input level. Values typically range from:
    /// - `-160 dB`: Complete silence or no input
    /// - `-60 dB` to `-40 dB`: Very quiet speech
    /// - `-40 dB` to `-20 dB`: Normal speech
    /// - `-20 dB` to `0 dB`: Loud speech or noise
    /// - `0 dB`: Maximum level (clipping may occur)
    ///
    /// The value updates at the display refresh rate (typically 60Hz) for
    /// smooth UI animations.
    ///
    /// ## Usage Example
    ///
    /// ```swift
    /// // Observe meter changes with Combine
    /// recorder.$meters
    ///     .map { dB in
    ///         // Convert dB to normalized value (0...1)
    ///         return max(0, min(1, (dB + 160) / 160))
    ///     }
    ///     .sink { normalizedLevel in
    ///         updateWaveformUI(level: normalizedLevel)
    ///     }
    /// ```
    ///
    /// - Note: Returns `0` when recording is not active.
    @Published open private(set) var meters: Float = 0

    /// Indicates whether audio recording is currently active.
    ///
    /// This property reflects the actual recording state, which may differ
    /// from the desired state due to:
    /// - Missing microphone permissions
    /// - Audio session interruptions (phone calls, alarms)
    /// - Audio session category incompatibility
    /// - System resource constraints
    ///
    /// ## Observable
    ///
    /// As a `@Published` property, you can observe changes using Combine:
    ///
    /// ```swift
    /// recorder.$isRecording
    ///     .sink { isRecording in
    ///         updateRecordingUI(active: isRecording)
    ///     }
    /// ```
    ///
    /// ## State Synchronization
    ///
    /// This property automatically synchronizes with:
    /// - Active call microphone state
    /// - Audio session interruptions
    /// - Application lifecycle events
    ///
    /// - Important: Always check this property to determine the actual
    ///   recording state rather than assuming recording started successfully
    ///   after calling `startRecording()`.
    @Published open private(set) var isRecording: Bool = false

    /// The store managing recording state.
    private let store: Store<Namespace>

    /// Container for managing Combine subscriptions.
    private let disposableBag = DisposableBag()

    /// Initializes a new audio recorder instance.
    ///
    /// The recorder is initialized with default settings optimized for
    /// voice recording during calls. During initialization:
    /// 1. Creates the internal state store
    /// 2. Sets up bindings between store state and published properties
    /// 3. Prepares middleware for handling recording lifecycle
    ///
    /// The recorder automatically synchronizes its `isRecording` and
    /// `meters` properties with the internal store state, ensuring UI
    /// updates happen on the main thread.
    public convenience init() {
        self.init(Namespace.store(initialState: .initial))
    }

    init(_ store: Store<Namespace>) {
        self.store = store
        // Bind store's recording state to the published property
        store
            .publisher(\.isRecording)
            .assign(to: \.isRecording, onWeak: self)
            .store(in: disposableBag)

        // Bind store's meter values to the published property
        store
            .publisher(\.meter)
            .assign(to: \.meters, onWeak: self)
            .store(in: disposableBag)
    }

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
    open func startRecording(ignoreActiveCall: Bool = false) {
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
    open func stopRecording() {
        store.dispatch(.setIsRecording(false))
    }

    func dispatch(_ action: Namespace.Action) {
        store.dispatch(action)
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
