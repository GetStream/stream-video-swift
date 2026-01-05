//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        updateMetersCancellable = audioRecorder
            .$meters
            .compactMap { [weak self] in self?.normaliseAndAppend($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevels, onWeak: self)
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

    public func startListening(ignoreActiveCall: Bool = false) async {
        log.warning("Method \(#function) has been deprecated and will be removed in the future.")
    }

    public func stopListening() async {
        log.warning("Method \(#function) has been deprecated and will be removed in the future.")
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
