//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// This class abstracts the usage of AVAudioRecorder, providing a convenient way to record and manage
/// audio streams. It handles setting up the recording environment, starting and stopping recording, and
/// publishing the average power of the audio signal. Additionally, it adjusts its behavior based on the
/// presence of an active call, automatically stopping recording if needed.
open class StreamCallAudioRecorder: @unchecked Sendable {
    private let store = CallAudioRecording.store(initialState: .initial)

    /// A public publisher that exposes the average power of the audio signal.
    open private(set) lazy var metersPublisher: AnyPublisher<Float, Never> = store
        .publisher(\.meter)

    /// Initializes the recorder with a custom builder and audio session.
    ///
    /// - Parameter audioRecorderBuilder: The builder used to create the recorder.
    public init() {}

    // MARK: - Public API

    /// Starts recording audio asynchronously.
    /// - Parameters:
    /// - ignoreActiveCall: Instructs the internal AudioRecorder to ignore the existence of an activeCall
    /// and start recording anyway.
    open func startRecording(ignoreActiveCall: Bool = false) async {
        if ignoreActiveCall {
            store.dispatch(.setShouldRecord(true))
        }

        store.dispatch(.setIsRecording(true))
    }

    /// Stops recording audio asynchronously.
    open func stopRecording() async {
        store.dispatch(.setIsRecording(false))
    }
}

/// Provides the default value of the `StreamCallAudioRecorder` class.
struct StreamCallAudioRecorderKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamCallAudioRecorder = StreamCallAudioRecorder()
}

extension InjectedValues {
    public var callAudioRecorder: StreamCallAudioRecorder {
        get {
            Self[StreamCallAudioRecorderKey.self]
        }
        set {
            Self[StreamCallAudioRecorderKey.self] = newValue
        }
    }
}
