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
            .scan([Float](repeating: 0.0, count: valueLimit)) { [audioNormaliser, valueLimit] levels, newMeter in
                let normalised = audioNormaliser.normalise(newMeter)
                var result = levels
                result.append(normalised)
                if result.count > valueLimit {
                    result = Array(result.dropFirst())
                }
                return result
            }
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

}

extension MicrophoneChecker: @unchecked Sendable {}
