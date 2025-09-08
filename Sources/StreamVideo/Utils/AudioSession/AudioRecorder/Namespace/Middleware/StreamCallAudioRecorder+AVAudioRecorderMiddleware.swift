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

        /// The audio store for managing permissions and session state.
        @Injected(\.permissions) private var permissions

        /// Builder for creating and caching the audio recorder instance.
        private var audioRecorder: AVAudioRecorder?

        /// Serial queue for recorder operations to ensure thread safety.
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        
        /// Subscription for publishing meter updates at refresh rate.
        private var updateMetersCancellable: AnyCancellable?

        init(audioRecorder: AVAudioRecorder? = nil) {
            self.audioRecorder = audioRecorder
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

                if audioRecorder == nil {
                    do {
                        self.audioRecorder = try AVAudioRecorder.build()
                    } catch {
                        log.error(error, subsystems: .audioRecording)
                        return
                    }
                }

                guard let audioRecorder else {
                    return
                }

                if updateMetersCancellable != nil {
                    // In order for AVAudioRecorder to keep receive metering updates
                    // we need to stop and start everytime there is a change in the
                    // AVAudioSession configuration.
                    audioRecorder.stop()
                    audioRecorder.isMeteringEnabled = false
                }

                updateMetersCancellable?.cancel()
                updateMetersCancellable = nil

                do {
                    let hasPermission = try await permissions.requestMicrophonePermission()
                    audioRecorder.isMeteringEnabled = true

                    guard
                        hasPermission,
                        audioRecorder.record()
                    else {
                        dispatcher?.dispatch(.setIsRecording(false))
                        audioRecorder.isMeteringEnabled = false
                        return
                    }

                    updateMetersCancellable = DefaultTimer
                        .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate)
                        .map { [weak audioRecorder] _ in audioRecorder?.updateMeters() }
                        .compactMap { [weak audioRecorder] in audioRecorder?.averagePower(forChannel: 0) }
                        .sink { [weak self] in self?.dispatcher?.dispatch(.setMeter($0)) }

                    log.debug("AVAudioRecorder started...", subsystems: .audioRecording)
                } catch {
                    log.error(error, subsystems: .audioRecording)
                }
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
                guard
                    let self,
                    updateMetersCancellable != nil,
                    let audioRecorder
                else {
                    self?.updateMetersCancellable?.cancel()
                    self?.updateMetersCancellable = nil
                    return
                }

                audioRecorder.stop()
                audioRecorder.isMeteringEnabled = false
                updateMetersCancellable?.cancel()
                updateMetersCancellable = nil
                log.debug("AVAudioRecorder stopped.", subsystems: .audioRecording)
            }
        }
    }
}
