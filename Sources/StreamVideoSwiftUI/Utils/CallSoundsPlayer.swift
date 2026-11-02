//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

/// Deals with sounds that are played during calls.
///
/// - Note: Audio-player access is confined to the serial processing queue.
///   Subclasses must synchronize their own mutable state when using
///   `@unchecked Sendable`.
open class CallSoundsPlayer: @unchecked Sendable {
    
    @Injected(\.sounds) private var sounds
    
    private var audioPlayer: AVAudioPlayer?
    // Serialize playback and stopping to prevent concurrent player access
    // and keep audio setup off the main thread (IOS-2073).
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    public init() {}

    /// Plays the sound for an incoming call.
    /// Playback starts asynchronously on the processing queue.
    open func playIncomingCallSound() {
        processingQueue.addOperation { [weak self] in
            guard let self else { return }
            playSound(sounds.incomingCallSound)
        }
    }
    
    /// Plays the sound for an outgoing call.
    /// Playback starts asynchronously on the processing queue.
    open func playOutgoingCallSound() {
        processingQueue.addOperation { [weak self] in
            guard let self else { return }
            playSound(sounds.outgoingCallSound)
        }
    }
    
    /// Stops playing the ongoing sound.
    /// Playback stops asynchronously on the processing queue.
    open func stopOngoingSound() {
        processingQueue.addOperation { [weak self] in
            guard let self else { return }
            audioPlayer?.stop()
            audioPlayer = nil
        }
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
