//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

/// Checks the audio capabilities of the device.
public class MicrophoneChecker: ObservableObject {
    
    /// Returns the last three decibel values.
    @Published public var audioLevels: [Float]
    
    private var timer: Timer?
    
    private let valueLimit: Int
    
    private var audioRecorder: AVAudioRecorder?
    
    private let audioFilename: URL = {
        let documentPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("recording.wav")
        return audioFilename
    }()

    private lazy var audioNormaliser: AudioValuePercentageNormaliser = .init()

    public init(valueLimit: Int = 3) {
        self.valueLimit = valueLimit
        self.audioLevels = [Float](repeating: 0.0, count: valueLimit)
        setUpAudioCapture()
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
    public func startListening() {
        captureAudio()
    }
    
    /// Stops listening to audio updates.
    public func stopListening() {
        stopTimer()
        stopAudioRecorder()
    }
    
    //MARK: - private
    
    private func setUpAudioCapture() {
        let recordingSession = AVAudioSession.sharedInstance()
                
        do {
            try recordingSession.setCategory(.playAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { result in
                guard result else { return }
            }
            captureAudio()
        } catch {
            log.error("Failed to set up recording session", error: error)
        }
    }
    
    private func captureAudio() {
        // `kAudioFormatLinearPCM` is being used to be able to support multiple
        // instances of AVAudioRecorders. (useful when using MicrophoneChecker
        // during a Call).
        // https://stackoverflow.com/a/8575101
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let newAudioRecorder: AVAudioRecorder
        do {
            newAudioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        } catch {
            log.error("Failed to start recording process", error: error)
            return
        }

        newAudioRecorder.record()
        newAudioRecorder.isMeteringEnabled = true
        self.audioRecorder = newAudioRecorder
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            newAudioRecorder.updateMeters()
            let decibel = newAudioRecorder.averagePower(forChannel: 0)
            let normalisedAudioLevel = self.audioNormaliser.normalise(decibel)
            var temp = self.audioLevels
            temp.append(normalisedAudioLevel)
            if temp.count > self.valueLimit {
                temp = Array(temp.dropFirst())
            }
            self.audioLevels = temp
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func stopAudioRecorder() {
        self.audioRecorder?.stop()
        self.audioRecorder = nil
    }

    deinit {
        stopTimer()
        stopAudioRecorder()
        do {
            try FileManager.default.removeItem(at: audioFilename)
            log.debug("Successfully deleted audio filename")
        } catch {
            log.error("Error deleting audio filename: \(error.localizedDescription)", error: error)
        }
    }
}
