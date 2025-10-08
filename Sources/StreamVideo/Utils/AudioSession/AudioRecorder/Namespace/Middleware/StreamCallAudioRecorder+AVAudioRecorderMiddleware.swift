//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension StreamCallAudioRecorder.Namespace {
    /// Middleware that manages the `AVAudioRecorder` instance for audio
    /// recording.
    ///
    /// This middleware handles:
    /// - Creating and configuring the audio recorder
    /// - Starting and stopping recording based on state changes
    /// - Publishing audio meter levels at the display refresh rate
    /// - Managing recording permissions
    ///
    /// ## Thread Safety
    ///
    /// Recording operations are performed on a serial operation queue to
    /// ensure thread safety when accessing the recorder instance.
    final class AVAudioRecorderMiddleware: Middleware<StreamCallAudioRecorder.Namespace>, @unchecked Sendable {

        enum Mode: Equatable {
            case invalid
            case audioRecorder(AVAudioRecorder)
            case audioDeviceModule(AudioDeviceModule)
        }

        /// The audio store for managing permissions and session state.
        @Injected(\.permissions) private var permissions
        @Injected(\.audioStore) private var audioStore

        private var mode: Mode

        /// Serial queue for recorder operations to ensure thread safety.
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        
        /// Subscription for publishing meter updates at refresh rate.
        private var updateMetersCancellable: AnyCancellable?
        private var audioDeviceModuleCancellable: AnyCancellable?

        init(audioRecorder: AVAudioRecorder? = nil) {
            if let audioRecorder {
                mode = .audioRecorder(audioRecorder)
            } else if let audioRecorder = try? AVAudioRecorder.build() {
                mode = .audioRecorder(audioRecorder)
            } else {
                mode = .invalid
            }

            super.init()

            audioDeviceModuleCancellable = audioStore
                .publisher(\.audioDeviceModule)
                .receive(on: processingQueue)
                .sink { [weak self] in
                    if let audioDeviceModule = $0 {
                        self?.mode = .audioDeviceModule(audioDeviceModule)
                        if self?.updateMetersCancellable != nil {
                            self?.stopRecording()
                            self?.startRecording()
                        }
                    }
                }
        }

        // MARK: - Middleware

        /// Processes actions to manage audio recording state.
        ///
        /// Responds to:
        /// - `.setIsRecording`: Starts or stops recording
        /// - `.setIsInterrupted`: Pauses recording during interruptions
        /// - `.setShouldRecord`: Initiates recording when needed
        ///
        /// - Parameters:
        ///   - state: The current store state.
        ///   - action: The action being processed.
        ///   - file: Source file of the action dispatch.
        ///   - function: Function name of the action dispatch.
        ///   - line: Line number of the action dispatch.
        override func apply(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .setIsRecording(value):
                if value, state.shouldRecord, !state.isInterrupted {
                    startRecording()
                } else {
                    stopRecording()
                }
            case let .setIsInterrupted(value):
                if value {
                    stopRecording()
                } else if !value, state.shouldRecord {
                    startRecording()
                } else {
                    break
                }

            case let .setShouldRecord(value):
                if value, !state.isInterrupted {
                    startRecording()
                } else if !value {
                    stopRecording()
                } else {
                    break
                }

            case .setMeter:
                break
            }
        }

        // MARK: - Private Helpers

        /// Starts audio recording asynchronously.
        ///
        /// This method:
        /// 1. Builds the audio recorder if needed
        /// 2. Requests recording permission
        /// 3. Enables metering and starts recording
        /// 4. Sets up a timer to publish meter updates
        private func startRecording() {
            processingQueue.addTaskOperation { [weak self] in
                guard
                    let self
                else {
                    return
                }

                guard mode != .invalid else {
                    log.warning(
                        "Unable to start meters observation as mode set to .none",
                        subsystems: .audioRecording
                    )
                    return
                }

                let mode = self.mode
                stopObservation(for: mode)

                guard await checkRequiredPermissions() else {
                    dispatcher?.dispatch(.setIsRecording(false))
                    return
                }

                startObservation(for: mode)
            }
        }

        /// Stops audio recording and cleans up resources.
        ///
        /// This method:
        /// 1. Stops the active recording
        /// 2. Disables metering
        /// 3. Cancels the meter update timer
        private func stopRecording() {
            processingQueue.addOperation { [weak self] in
                guard let self else { return }
                stopObservation(for: mode)
            }
        }

        private func checkRequiredPermissions() async -> Bool {
            do {
                return try await permissions.requestMicrophonePermission()
            } catch {
                log.error(error, subsystems: .audioRecording)
                return false
            }
        }

        private func stopObservation(for mode: Mode) {
            guard updateMetersCancellable != nil else {
                return
            }

            updateMetersCancellable?.cancel()
            updateMetersCancellable = nil

            switch mode {
            case .invalid:
                break
            case .audioRecorder(let audioRecorder):
                // In order for AVAudioRecorder to keep receive metering updates
                // we need to stop and start everytime there is a change in the
                // AVAudioSession configuration.
                audioRecorder.stop()
                audioRecorder.isMeteringEnabled = false
                log.debug("AVAudioRecorder stopped.", subsystems: .audioRecording)

            case .audioDeviceModule:
                log.debug("AVAudioDeviceModule audioLevel observation stopped.", subsystems: .audioRecording)
            }
        }

        private func startObservation(for mode: Mode) {
            guard updateMetersCancellable == nil else {
                return
            }

            switch mode {
            case .invalid:
                break

            case .audioRecorder(let audioRecorder):
                audioRecorder.isMeteringEnabled = true
                audioRecorder.record()
                updateMetersCancellable = DefaultTimer
                    .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate)
                    .map { [weak audioRecorder] _ in audioRecorder?.updateMeters() }
                    .compactMap { [weak audioRecorder] in audioRecorder?.averagePower(forChannel: 0) }
                    .sink { [weak self] in self?.dispatcher?.dispatch(.setMeter($0)) }
                log.debug("AVAudioRecorder started...", subsystems: .audioRecording)

            case .audioDeviceModule(let audioDeviceModule):
                updateMetersCancellable = audioDeviceModule
                    .audioLevelPublisher
                    .log(.debug, subsystems: .audioRecording) { "AVAudioDeviceModule audioLevel observation value:\($0)." }
                    .sink { [weak self] in self?.dispatcher?.dispatch(.setMeter($0)) }
                log.debug("AVAudioDeviceModule audioLevel observation started...", subsystems: .audioRecording)
            }
        }
    }
}
