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
open class StreamAudioRecorder: @unchecked Sendable {

    /// The builder used to create the AVAudioRecorder instance.
    let audioRecorderBuilder: AVAudioRecorderBuilder

    /// The audio session used for recording and playback.
    let audioSession: AudioSessionProtocol

    /// A private task responsible for setting up the recorder in the background.
    private var setUpTask: Task<Void, Never>?

    /// A cancellable used to schedule the update of audio meters.
    private(set) var updateMetersTimerCancellable: AnyCancellable?

    /// A PassthroughSubject that publishes the average power of the audio signal.
    private var _metersPublisher: PassthroughSubject<Float, Never> = .init()

    /// A public publisher that exposes the average power of the audio signal.
    open private(set) lazy var metersPublisher: AnyPublisher<Float, Never> = _metersPublisher.eraseToAnyPublisher()

    /// Indicates whether an active call is present, influencing recording behavior.
    public var hasActiveCall: Bool = false {
        didSet {
            if !hasActiveCall {
                Task {
                    await stopRecording()
                    try? audioSession.setActive(false, options: [])
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
        setUpTask?.cancel()
        setUpTask = nil
        do {
            try FileManager.default.removeItem(at: audioRecorderBuilder.fileURL)
            log.debug("Successfully deleted audio filename")
        } catch {
            log.error("Error deleting fileURL.", error: error)
        }
    }

    // MARK: - Public API

    /// Starts recording audio asynchronously.
    open func startRecording() async {
        await setUpAudioCaptureIfRequired { [weak self] audioRecorder in
            guard let self, self.hasActiveCall, !audioRecorder.isRecording else {
                return
            }

            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true

            log.debug("️Recording started.")
            self.updateMetersTimerCancellable = Foundation.Timer
                .publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self, audioRecorder] _ in
                    Task { [weak self, audioRecorder] in
                        guard let self else { return }
                        audioRecorder.updateMeters()
                        self._metersPublisher.send(audioRecorder.averagePower(forChannel: 0))
                        log.debug("️Recording meters updated")
                    }
                }
        }
    }

    /// Stops recording audio asynchronously.
    open func stopRecording() async {
        guard let audioRecorder = await audioRecorderBuilder.result, audioRecorder.isRecording else {
            return
        }

        updateMetersTimerCancellable?.cancel()
        updateMetersTimerCancellable = nil
        audioRecorder.stop()
        do {
            try audioSession.setCategory(.playback)
        } catch {
            log.error("Failed to set AudiSession category to playback.", error: error)
        }
        log.debug("️Recording stopped.")
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
                    log.error("Failed to create AVAudioRecorder.", error: error)
                }
            }
        }
    }

    private func setUpAudioCaptureIfRequired(
        _ completionHandler: @escaping (AVAudioRecorder) async -> Void
    ) async {
        do {
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setActive(true, options: [])
            if
                await audioSession.requestRecordPermission(),
                let audioRecorder = await audioRecorderBuilder.result {
                await completionHandler(audioRecorder)
            }
        } catch {
            log.error("Failed to set up recording session", error: error)
        }
    }
}

/// Provides the default value of the `StreamAudioRecorder` class.
public struct StreamAudioRecorderKey: InjectionKey {
    public static var currentValue: StreamAudioRecorder = StreamAudioRecorder(
        filename: "recording.wav"
    )
}

extension InjectedValues {

    public var audioRecorder: StreamAudioRecorder {
        get {
            Self[StreamAudioRecorderKey.self]
        }
        set {
            Self[StreamAudioRecorderKey.self] = newValue
        }
    }
}
