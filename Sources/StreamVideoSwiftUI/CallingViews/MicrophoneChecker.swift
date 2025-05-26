//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamVideo

/// Checks the audio capabilities of the device.
public final class MicrophoneChecker: ObservableObject {

    /// Returns the last three decibel values.
    @Published public private(set) var audioLevels: [Float]

    private let valueLimit: Int
    private let audioNormaliser = AudioValuePercentageNormaliser()
    private let audioRecorder = InjectedValues[\.callAudioRecorder]
    private let serialQueue = SerialActorQueue()

    private var updateMetersCancellable: AnyCancellable?

    public init(
        valueLimit: Int = 3
    ) {
        self.valueLimit = valueLimit
        audioLevels = [Float](repeating: 0.0, count: valueLimit)
    }

    deinit {
        updateMetersCancellable?.cancel()
        updateMetersCancellable = nil
    }

    /// Checks if there are audible values available.
    public var isSilent: Bool {
        for audioLevel in audioLevels {
            if audioLevel > audioNormaliser.valueRange.lowerBound {
                return false
            }
        }
        return true
    }
    
    /// Starts listening to audio updates.
    /// - Parameters:
    /// - ignoreActiveCall: Instructs the internal AudioRecorder to ignore the existence of an activeCall
    /// and start recording anyway.
    public func startListening(ignoreActiveCall: Bool = false) async {
        do {
            try await serialQueue.sync { [weak self] in
                guard let self else {
                    return
                }
                await audioRecorder.startRecording(ignoreActiveCall: ignoreActiveCall)
                if updateMetersCancellable == nil {
                    updateMetersCancellable = audioRecorder
                        .metersPublisher
                        .compactMap { [weak self] in self?.normaliseAndAppend($0) }
                        .receive(on: DispatchQueue.main)
                        .assign(to: \.audioLevels, onWeak: self)
                }
            }
        } catch {
            log.error(error)
        }
    }
    
    /// Stops listening to audio updates.
    public func stopListening() async {
        guard audioRecorder.isRecording else {
            return
        }

        do {
            try await
                serialQueue.sync { [weak self] in
                    guard let self else {
                        return
                    }
                    await audioRecorder.stopRecording()
                    updateMetersCancellable?.cancel()
                    updateMetersCancellable = nil
                    _ = await Task { @MainActor [weak self] in
                        guard let self else {
                            return
                        }
                        audioLevels = [Float](repeating: 0.0, count: valueLimit)
                    }.result
                }
        } catch {
            log.error(error)
        }
    }
    
    // MARK: - private

    private func normaliseAndAppend(_ decibel: Float) -> [Float] {
        let normalisedAudioLevel = audioNormaliser.normalise(decibel)
        var temp = audioLevels
        temp.append(normalisedAudioLevel)
        if temp.count > valueLimit {
            temp = Array(temp.dropFirst())
        }
        return temp
    }
}

extension MicrophoneChecker: @unchecked Sendable {}
