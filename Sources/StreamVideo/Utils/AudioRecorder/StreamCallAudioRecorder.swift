//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// This class abstracts the usage of AVAudioRecorder, providing a convenient way to record and manage
/// audio streams. It handles setting up the recording environment, starting and stopping recording, and
/// publishing the average power of the audio signal. Additionally, it adjusts its behavior based on the
/// presence of an active call, automatically stopping recording if needed.
open class StreamCallAudioRecorder: @unchecked Sendable {

    @Injected(\.activeCallProvider) private var activeCallProvider

    /// The builder used to create the AVAudioRecorder instance.
    let audioRecorderBuilder: AVAudioRecorderBuilder

    /// The audio session used for recording and playback.
    let audioSession: AudioSessionProtocol

    /// A private task responsible for setting up the recorder in the background.
    private var setUpTask: Task<Void, Never>?

    private var hasActiveCallCancellable: AnyCancellable?

    /// A cancellable used to schedule the update of audio meters.
    private(set) var updateMetersTimerCancellable: AnyCancellable?

    /// A PassthroughSubject that publishes the average power of the audio signal.
    private var _metersPublisher: PassthroughSubject<Float, Never> = .init()

    /// A public publisher that exposes the average power of the audio signal.
    open private(set) lazy var metersPublisher: AnyPublisher<Float, Never> = _metersPublisher.eraseToAnyPublisher()

    /// Indicates whether an active call is present, influencing recording behavior.
    private var hasActiveCall: Bool = false {
        didSet {
            if !hasActiveCall {
                Task {
                    await stopRecording()
                    do {
                        /// It's safe to deactivate the session as a call isn't in progress.
                        try audioSession.setActive(false, options: [])
                    } catch {
                        log.error("🎙️Failed to deactivate AudioSession.", error: error)
                    }
                }
            }
        }
    }

    /// Initializes the recorder with a filename.
    ///
    /// - Parameter filename: The name of the file to record to.
    public init(filename: String) {
        audioRecorderBuilder = .init(inCacheDirectoryWithFilename: filename)
        audioSession = AVAudioSession.sharedInstance()

        setUp()
    }

    /// Initializes the recorder with a custom builder and audio session.
    ///
    /// - Parameter audioRecorderBuilder: The builder used to create the recorder.
    /// - Parameter audioSession: The audio session used for recording and playback.
    init(
        audioRecorderBuilder: AVAudioRecorderBuilder,
        audioSession: AudioSessionProtocol
    ) {
        self.audioRecorderBuilder = audioRecorderBuilder
        self.audioSession = audioSession

        setUp()
    }

    deinit {
        removeRecodingFile()
        setUpTask?.cancel()
        setUpTask = nil
        hasActiveCallCancellable?.cancel()
        hasActiveCallCancellable = nil
    }

    // MARK: - Public API

    /// Starts recording audio asynchronously.
    /// - Parameters:
    /// - ignoreActiveCall: Instructs the internal AudioRecorder to ignore the existence of an activeCall
    /// and start recording anyway.
    open func startRecording(ignoreActiveCall: Bool = false) async {
        do {
            let audioRecorder = try await setUpAudioCaptureIfRequired()
            guard hasActiveCall || ignoreActiveCall, !audioRecorder.isRecording else {
                log
                    .info(
                        "🎙️Attempted to start recording but failed. hasActiveCall:\(hasActiveCall) isRecording:\(audioRecorder.isRecording)"
                    )
                return
            }
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true

            log.debug("️🎙️Recording started.")
            updateMetersTimerCancellable = Foundation.Timer
                .publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self, audioRecorder] _ in
                    Task { [weak self, audioRecorder] in
                        guard let self else { return }
                        audioRecorder.updateMeters()
                        self._metersPublisher.send(audioRecorder.averagePower(forChannel: 0))
                        log.debug("️🎙️Recording meters updated")
                    }
                }
        } catch {
            log.error("🎙️Failed to set up recording session", error: error)
        }
    }

    /// Stops recording audio asynchronously.
    open func stopRecording() async {
        guard
            let audioRecorder = await audioRecorderBuilder.result,
            audioRecorder.isRecording
        else {
            return
        }

        updateMetersTimerCancellable?.cancel()
        updateMetersTimerCancellable = nil
        audioRecorder.stop()
        removeRecodingFile()
        do {
            /// - Warning: It's on purpose that we don't deactivate the AudioSession here as a
            /// call is in progress.
            try audioSession.setCategory(.playback)
        } catch {
            log.error("🎙️Failed to set AudiSession category to playback.", error: error)
        }
        log.debug("️🎙️Recording stopped.")
    }

    // MARK: - Private helpers

    private func setUp() {
        setUpTask = Task {
            do {
                #if DEBUG
                let startedOn = Date()
                try await audioRecorderBuilder.build()
                let diff = Date().timeIntervalSince1970 - startedOn.timeIntervalSince1970
                try Task.checkCancellation() // This required to ensure that tests aren't crashing.
                log.debug("🎙️AVAudioRecorder creation took: \(diff) seconds.")
                #else
                try await audioRecorderBuilder.build()
                #endif
            } catch {
                if type(of: error) != CancellationError.self {
                    log.error("🎙️Failed to create AVAudioRecorder.", error: error)
                }
            }
        }

        hasActiveCallCancellable = activeCallProvider
            .hasActiveCallPublisher
            .receive(on: DispatchQueue.global(qos: .utility))
            .removeDuplicates()
            .sink { [weak self] in
                self?.hasActiveCall = $0
            }
    }

    private func setUpAudioCaptureIfRequired() async throws -> AVAudioRecorder {
        try audioSession.setCategory(.playAndRecord)
        try audioSession.setActive(true, options: [])

        guard
            await audioSession.requestRecordPermission()
        else {
            throw ClientError("🎙️Permission denied.")
        }

        guard
            let audioRecorder = await audioRecorderBuilder.result
        else {
            throw ClientError("🎙️Unable to fetch AVAudioRecorder instance.")
        }

        return audioRecorder
    }

    private func removeRecodingFile() {
        let fileURL = audioRecorderBuilder.fileURL
        do {
            try FileManager.default.removeItem(at: fileURL)
            log.debug("🎙️Successfully deleted audio filename")
        } catch {
            log.warning("🎙️Cannot delete \(fileURL).\(error)")
        }
    }
}

/// Provides the default value of the `StreamCallAudioRecorder` class.
public struct StreamCallAudioRecorderKey: InjectionKey {
    public static var currentValue: StreamCallAudioRecorder = StreamCallAudioRecorder(
        filename: "recording.wav"
    )
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
