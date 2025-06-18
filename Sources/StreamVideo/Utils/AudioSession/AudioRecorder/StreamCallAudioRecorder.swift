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
    private let processingQueue = SerialActorQueue()

    @Injected(\.activeCallProvider) private var activeCallProvider
    @Injected(\.activeCallAudioSession) private var activeCallAudioSession
    @Injected(\.timers) private var timers

    /// The builder used to create the AVAudioRecorder instance.
    let audioRecorderBuilder: AVAudioRecorderBuilder

    private let _isRecordingSubject: CurrentValueSubject<Bool, Never> = .init(false)
    var isRecordingPublisher: AnyPublisher<Bool, Never> {
        _isRecordingSubject.eraseToAnyPublisher()
    }

    private var hasActiveCallCancellable: AnyCancellable?

    /// A cancellable used to schedule the update of audio meters.
    private(set) var updateMetersTimerCancellable: AnyCancellable?

    /// A PassthroughSubject that publishes the average power of the audio signal.
    private var _metersPublisher: PassthroughSubject<Float, Never> = .init()

    /// A public publisher that exposes the average power of the audio signal.
    open private(set) lazy var metersPublisher: AnyPublisher<Float, Never> = _metersPublisher.eraseToAnyPublisher()

    @Atomic public private(set) var isRecording: Bool = false {
        willSet {
            activeCallAudioSession?.isRecording = newValue
            _isRecordingSubject.send(newValue)
        }
    }

    /// Indicates whether an active call is present, influencing recording behaviour.
    private var hasActiveCall: Bool = false {
        didSet {
            guard hasActiveCall != oldValue else { return }
            log.debug("🎙️updated with hasActiveCall:\(hasActiveCall).")
            if !hasActiveCall {
                Task(disposableBag: disposableBag) { [weak self] in await self?.stopRecording() }
            }
        }
    }

    private let disposableBag = DisposableBag()

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
        hasActiveCallCancellable?.cancel()
        hasActiveCallCancellable = nil
    }

    // MARK: - Public API

    /// Starts recording audio asynchronously.
    /// - Parameters:
    /// - ignoreActiveCall: Instructs the internal AudioRecorder to ignore the existence of an activeCall
    /// and start recording anyway.
    open func startRecording(ignoreActiveCall: Bool = false) async {
        await performOperation { [weak self] in
            guard
                let self,
                !isRecording
            else {
                return
            }

            var audioRecorder: AVAudioRecorder?
            do {
                audioRecorder = try await setUpAudioCaptureIfRequired()
            } catch {
                log.error("🎙️Failed to set up recording session", error: error)
            }

            guard
                let audioRecorder,
                hasActiveCall || ignoreActiveCall
            else {
                return // No-op
            }

            await deferSessionActivation()
            audioRecorder.record()
            isRecording = true
            audioRecorder.isMeteringEnabled = true

            updateMetersTimerCancellable?.cancel()
            disposableBag.remove("update-meters")
            updateMetersTimerCancellable = timers
                .timer(for: ScreenPropertiesAdapter.currentValue.refreshRate)
                .sinkTask(storeIn: disposableBag, identifier: "update-meters") { [weak self, audioRecorder] _ in
                    audioRecorder.updateMeters()
                    self?._metersPublisher.send(audioRecorder.averagePower(forChannel: 0))
                }

            log.debug("️🎙️Recording started.")
        }
    }

    /// Stops recording audio asynchronously.
    open func stopRecording() async {
        await performOperation { [weak self] in
            self?.updateMetersTimerCancellable?.cancel()
            self?.updateMetersTimerCancellable = nil
            self?.disposableBag.remove("update-meters")

            guard
                let self,
                isRecording,
                let audioRecorder = audioRecorderBuilder.result
            else {
                return
            }

            audioRecorder.stop()

            // Ensure that recorder has stopped recording.
            _ = try? await audioRecorder
                .publisher(for: \.isRecording)
                .filter { $0 == false }
                .nextValue(timeout: 0.5)

            isRecording = false
            removeRecodingFile()

            log.debug("️🎙️Recording stopped.")
        }
    }

    // MARK: - Private helpers

    private func performOperation(
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @Sendable @escaping () async -> Void
    ) async {
        do {
            try await processingQueue.sync {
                await operation()
                return () // Explicitly return Void
            }
        } catch {
            log.error(ClientError(with: error, file, line))
        }
    }

    private func setUp() {
        do {
            try audioRecorderBuilder.build()
        } catch {
            if type(of: error) != CancellationError.self {
                log.error("🎙️Failed to create AVAudioRecorder.", error: error)
            }
        }

        hasActiveCallCancellable = activeCallProvider
            .hasActiveCallPublisher
            .receive(on: DispatchQueue.global(qos: .utility))
            .removeDuplicates()
            .assign(to: \.hasActiveCall, onWeak: self)
    }

    private func setUpAudioCaptureIfRequired() async throws -> AVAudioRecorder {
        guard
            await activeCallAudioSession?.requestRecordPermission() == true
        else {
            throw ClientError("🎙️Permission denied.")
        }

        guard
            let audioRecorder = audioRecorderBuilder.result
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

    private func deferSessionActivation() async {
        guard let activeCallAudioSession else {
            return
        }
        _ = try? await activeCallAudioSession
            .$category
            .filter { $0 == .playAndRecord }
            .nextValue(timeout: 1)
    }
}

/// Provides the default value of the `StreamCallAudioRecorder` class.
struct StreamCallAudioRecorderKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamCallAudioRecorder = StreamCallAudioRecorder(
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
