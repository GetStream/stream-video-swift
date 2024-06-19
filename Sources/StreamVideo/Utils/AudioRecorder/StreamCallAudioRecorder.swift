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

    private let queue = UnfairQueue()
    private var _isRecording: Bool = false
    private var isRecording: Bool {
        get { queue.sync { _isRecording } }
        set { queue.sync { _isRecording = newValue } }
    }

    /// Indicates whether an active call is present, influencing recording behaviour.
    private var hasActiveCall: Bool = false {
        didSet {
            guard hasActiveCall != oldValue else { return }
            log.debug("🎙️updated with hasActiveCall:\(hasActiveCall).")
            if !hasActiveCall {
                Task {
                    await stopRecording()
                    do {
                        /// It's safe to deactivate the session as a call isn't in progress.
                        try audioSession.setActive(false, options: [])
                        log.debug("🎙️AudioSession deactivated.")
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
            guard hasActiveCall || ignoreActiveCall, !isRecording else {
                log
                    .info(
                        "🎙️Attempted to start recording but failed. hasActiveCall:\(hasActiveCall) isRecording:\(isRecording)"
                    )
                return
            }
            audioRecorder.record()
            isRecording = true
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
                    }
                }
        } catch {
            isRecording = false
            log.error("🎙️Failed to set up recording session", error: error)
        }
    }

    /// Stops recording audio asynchronously.
    open func stopRecording() async {
        updateMetersTimerCancellable?.cancel()
        updateMetersTimerCancellable = nil
        log.debug("🎙️Meters cancellable nullified.")

        guard
            isRecording,
            let audioRecorder = await audioRecorderBuilder.result
        else {
            return
        }

        audioRecorder.stop()
        isRecording = false
        removeRecodingFile()
        log.debug("️🎙️Recording stopped.")
    }

    // MARK: - Private helpers

    private func setUp() {
        setUpTask?.cancel()
        setUpTask = Task {
            do {
                try await audioRecorderBuilder.build()
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
struct StreamCallAudioRecorderKey: InjectionKey {
    static var currentValue: StreamCallAudioRecorder = StreamCallAudioRecorder(
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
