//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

/// Deals with sounds that are played during calls.
open class CallSoundsPlayer {
    
    @Injected(\.sounds) private var sounds
    
    private var audioPlayer: AVAudioPlayer?
    
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
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - private
    
    private func playSound(_ soundFile: Resource) {
        let bundle: Bundle = sounds.bundle
        guard let soundURL = bundle.url(forResource: soundFile.name, withExtension: soundFile.extension) else {
            log.warning("There's no sound available")
            return
        }
        audioPlayer = try? AVAudioPlayer(contentsOf: soundURL)
        audioPlayer?.numberOfLoops = 10
        audioPlayer?.play()
    }
}
