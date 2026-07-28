//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

/// Deals with sounds that are played during calls.
open class CallSoundsPlayer {
    
    @Injected(\.sounds) private var sounds
    
    private let playback = CallSoundsPlayerPlayback()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    
    public init() {}

    /// Plays the sound for an incoming call.
    open func playIncomingCallSound() {
        playSound(sounds.incomingCallSound)
    }
    
    /// Plays the sound for an outgoing call.
    open func playOutgoingCallSound() {
        playSound(sounds.outgoingCallSound)
    }
    
    /// Stops playing the ongoing sound.
    open func stopOngoingSound() {
        let playback = playback
        processingQueue.addTaskOperation {
            await playback.stop()
        }
    }
    
    // MARK: - private
    
    private func playSound(_ soundFile: Resource) {
        let bundle: Bundle = sounds.bundle
        guard let soundURL = bundle.url(forResource: soundFile.name, withExtension: soundFile.extension) else {
            log.warning("There's no sound available")
            return
        }

        let playback = playback
        processingQueue.addTaskOperation {
            await playback.play(soundURL)
        }
    }
}

private actor CallSoundsPlayerPlayback {
    private var audioPlayer: AVAudioPlayer?

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func play(_ soundURL: URL) {
        audioPlayer?.stop()

        guard let audioPlayer = try? AVAudioPlayer(contentsOf: soundURL) else {
            return
        }

        audioPlayer.numberOfLoops = 10
        self.audioPlayer = audioPlayer
        audioPlayer.play()
    }
}
