//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

/// Checks the audio capabilities of the device.
public class MicrophoneChecker: ObservableObject {
    
    /// Returns the last three decibel values.
    @Published public var decibels: [Float]
    
    private static let minimalDecibelValue: Float = -120
    
    private var timer: Timer?
    
    private let valueLimit: Int
    
    private let audioFilename: URL = {
        let documentPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("recording.m4a")
        return audioFilename
    }()
    
    public init(valueLimit: Int = 3) {
        self.valueLimit = valueLimit
        self.decibels = [Float](repeating: 0.0, count: valueLimit)
        setUpAudioCapture()
    }
    
    /// Checks if there are decibel values available.
    public var hasDecibelValues: Bool {
        for decibel in decibels {
            if decibel > Self.minimalDecibelValue {
                return true
            }
        }
        return false
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
            log.error("Failed to set up recording session")
        }
    }
    
    private func captureAudio() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                audioRecorder.updateMeters()
                let decibel = audioRecorder.averagePower(forChannel: 0)
                var temp = self.decibels
                temp.append(decibel)
                if temp.count > self.valueLimit {
                    temp = Array(temp.dropFirst())
                }
                self.decibels = temp
            }
        } catch {
            log.error("Failed to start recording process")
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        do {
            try FileManager.default.removeItem(at: audioFilename)
            log.debug("Successfully deleted audio filename")
        } catch {
            log.error("Error deleting audio filename: \(error.localizedDescription)")
        }
    }
}
