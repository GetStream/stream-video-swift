//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    private struct StartRecordingRequest: Hashable { var hasActiveCall, ignoreActiveCall, isRecording: Bool }

    @Injected(\.activeCallProvider) private var activeCallProvider
    @Injected(\.activeCallAudioSession) private var activeCallAudioSession

    /// The builder used to create the AVAudioRecorder instance.
    let audioRecorderBuilder: AVAudioRecorderBuilder

    /// A private task responsible for setting up the recorder in the background.
    private var setUpTask: Task<Void, Error>?

    private var hasActiveCallCancellable: AnyCancellable?

    /// A cancellable used to schedule the update of audio meters.
    private(set) var updateMetersTimerCancellable: AnyCancellable?

    /// A PassthroughSubject that publishes the average power of the audio signal.
    private var _metersPublisher: PassthroughSubject<Float, Never> = .init()

    /// A public publisher that exposes the average power of the audio signal.
    open private(set) lazy var metersPublisher: AnyPublisher<Float, Never> = _metersPublisher.eraseToAnyPublisher()

    @Atomic private var isRecording: Bool = false

    /// Indicates whether an active call is present, influencing recording behaviour.
    private var hasActiveCall: Bool = false {
        didSet {
            guard hasActiveCall != oldValue else { return }
            log.debug("🎙️updated with hasActiveCall:\(hasActiveCall).")
            if !hasActiveCall {
                Task { await stopRecording() }
            }
        }
    }

    private var lastStartRecordingRequest: StartRecordingRequest?

    /// Initializes the recorder with a filename.
    ///
    /// - Parameter filename: The name of the file to record to.
    public init(filename: String) {
        audioRecorderBuilder = .init(inCacheDirectoryWithFilename: filename)

        setUp()
    }

    /// Initializes the recorder with a custom builder and audio session.
    ///
    /// - Parameter audioRecorderBuilder: The builder used to create the recorder.
    init(
        audioRecorderBuilder: AVAudioRecorderBuilder
    ) {
        self.audioRecorderBuilder = audioRecorderBuilder

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
            let startRecordingRequest = StartRecordingRequest(
                hasActiveCall: hasActiveCall,
                ignoreActiveCall: ignoreActiveCall,
                isRecording: isRecording
            )

            guard startRecordingRequest != lastStartRecordingRequest else {
                lastStartRecordingRequest = startRecordingRequest
                return
            }

            lastStartRecordingRequest = startRecordingRequest
            guard
                startRecordingRequest.hasActiveCall || startRecordingRequest.ignoreActiveCall,
                !startRecordingRequest.isRecording
            else {
                log.debug(
                    """
                    🎙️Attempted to start recording but failed
                    hasActiveCall: \(startRecordingRequest.hasActiveCall)
                    ignoreActiveCall: \(startRecordingRequest.ignoreActiveCall)
                    isRecording: \(startRecordingRequest.isRecording)
                    """
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

        guard
            isRecording,
            let audioRecorder = await audioRecorderBuilder.result
        else {
            return
        }

        audioRecorder.stop()
        lastStartRecordingRequest = nil
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
        guard
            await activeCallAudioSession?.requestRecordPermission() == true
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
            log.debug("🎙️Cannot delete \(fileURL).\(error)")
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
