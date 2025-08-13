//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension CallAudioRecording {
    final class AVAudioRecorderMiddleware: Middleware<CallAudioRecording>, @unchecked Sendable {

        @Injected(\.audioStore) private var audioStore

        private let audioRecorderBuilder = AVAudioRecorderBuilder()
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var updateMetersCancellable: AnyCancellable?

        // MARK: - CallAudioRecorderMiddleware

        override func apply(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .setIsRecording(value):
                if value, state.shouldRecord {
                    startRecording()
                } else {
                    stopRecording()
                }
            case let .setIsInterrupted(value):
                if value {
                    stopRecording()
                } else if !value, state.shouldRecord, !state.isRecording {
                    startRecording()
                } else {
                    break
                }

            case let .setShouldRecord(value):
                if value, !state.isRecording {
                    startRecording()
                } else {
                    break
                }

            case .setMeter:
                break
            }
        }

        // MARK: - Private Helpers

        private func startRecording() {
            processingQueue.addTaskOperation { [weak self] in
                guard
                    let self,
                    updateMetersCancellable == nil
                else {
                    return
                }

                do {
                    try audioRecorderBuilder.build()
                } catch {
                    log.error(error, subsystems: .audioRecording)
                    return
                }

                guard let audioRecorder = audioRecorderBuilder.result else {
                    return
                }

                audioRecorder.isMeteringEnabled = true
                guard
                    await audioStore.requestRecordPermission(),
                    audioRecorder.record()
                else {
                    dispatcher?(.setIsRecording(false))
                    audioRecorder.isMeteringEnabled = false
                    return
                }

                updateMetersCancellable = DefaultTimer
                    .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate)
                    .map { [weak audioRecorder] _ in audioRecorder?.updateMeters() }
                    .compactMap { [weak audioRecorder] in audioRecorder?.averagePower(forChannel: 0) }
                    .sink { [weak self] in self?.dispatcher?(.setMeter($0)) }
            }
        }

        private func stopRecording() {
            processingQueue.addOperation { [weak self] in
                guard
                    let self,
                    updateMetersCancellable != nil,
                    let audioRecorder = audioRecorderBuilder.result
                else {
                    return
                }

                audioRecorder.stop()
                audioRecorder.isMeteringEnabled = false
                updateMetersCancellable?.cancel()
                updateMetersCancellable = nil
            }
        }
    }
}
