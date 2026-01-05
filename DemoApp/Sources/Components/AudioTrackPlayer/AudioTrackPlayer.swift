//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo

final class AudioTrackPlayer: NSObject, AVAudioPlayerDelegate {
    enum Track: String, Equatable, CaseIterable {
        case track1 = "track_1"
        case track2 = "track_2"

        var fileExtension: String {
            switch self {
            case .track1:
                return ".mp3"
            case .track2:
                return ".mp3"
            }
        }
    }

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var track: Track?

    private var audioPlayer: AVAudioPlayer?
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    func play(_ track: Track) {
        processingQueue.addTaskOperation { @MainActor [weak self] in
            guard
                let self,
                self.track != track,
                let url = Bundle.main.url(forResource: track.rawValue, withExtension: track.fileExtension),
                let audioPlayer = try? AVAudioPlayer(contentsOf: url)
            else {
                return
            }

            self.audioPlayer = audioPlayer
            audioPlayer.play()
            audioPlayer.numberOfLoops = 1000
            self.track = track
            self.isPlaying = true
        }
    }

    func stop() {
        processingQueue.addTaskOperation { @MainActor [weak self] in
            guard
                let self
            else {
                return
            }

            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying = false
            track = nil
        }
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        stop()
    }
}

extension AudioTrackPlayer: InjectionKey {
    static var currentValue: AudioTrackPlayer = .init()
}

extension InjectedValues {
    var audioPlayer: AudioTrackPlayer {
        get { Self[AudioTrackPlayer.self] }
        set { _ = newValue }
    }
}
