//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    private var updateMetersCancellable: AnyCancellable?

    public init(
        valueLimit: Int = 3
    ) {
        self.valueLimit = valueLimit
        audioLevels = [Float](repeating: 0.0, count: valueLimit)
    }

    deinit {
        updateMetersCancellable?.cancel()
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
    public func startListening() async {
        await audioRecorder.startRecording()
        if updateMetersCancellable == nil {
            updateMetersCancellable = audioRecorder
                .metersPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didReceiveUpdatedMeters($0) }
        }
    }
    
    /// Stops listening to audio updates.
    public func stopListening() async {
        await audioRecorder.stopRecording()
        updateMetersCancellable?.cancel()
        updateMetersCancellable = nil
        Task { @MainActor in
            audioLevels = [Float](repeating: 0.0, count: valueLimit)
        }
    }
    
    // MARK: - private

    private func didReceiveUpdatedMeters(_ decibel: Float) {
        let normalisedAudioLevel = audioNormaliser.normalise(decibel)
        var temp = audioLevels
        temp.append(normalisedAudioLevel)
        if temp.count > valueLimit {
            temp = Array(temp.dropFirst())
        }
        audioLevels = temp
    }
}

extension MicrophoneChecker: @unchecked Sendable {}
