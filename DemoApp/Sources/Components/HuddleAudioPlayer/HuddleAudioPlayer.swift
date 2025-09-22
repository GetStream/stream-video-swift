//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

final class HuddleAudioPlayer: ObservableObject {

    enum Status { case idle, playing, paused }

    static let shared = HuddleAudioPlayer()

    private let audioPlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var timeObservationToken: Any?
    private var durationTask: Task<Void, Never>?

    @Published private(set) var status: Status = .idle

    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentTime: TimeInterval = 0

    @Published private(set) var selectedTrack: HuddleTrack? {
        willSet { updateAudioPlayer(with: newValue) }
    }

    @MainActor
    func startPlaying(_ track: HuddleTrack) {
        guard selectedTrack != track else {
            return
        }

        selectedTrack = track
    }

    @MainActor
    func togglePause() {
        switch status {
        case .idle:
            break
        case .playing:
            audioPlayer.pause()
            status = .paused
        case .paused:
            audioPlayer.play()
            status = .playing
        }
    }

    @MainActor
    func stopPlaying() {
        selectedTrack = nil
    }

    // MARK: - Private Helpers

    deinit {
        durationTask?.cancel()
        removeTimeObserver()
    }

    private func updateAudioPlayer(with track: HuddleTrack?) {
        guard
            let track,
            track.exists,
            let url = track.url
        else {
            resetForIdleState()
            return
        }

        durationTask?.cancel()
        durationTask = nil
        removeTimeObserver()
        resetProgress()

        let item = AVPlayerItem(url: url)
        audioPlayer.replaceCurrentItem(with: item)
        looper = .init(player: audioPlayer, templateItem: item)

        observeCurrentTime()
        loadDuration(for: item)

        audioPlayer.play()
        status = .playing
    }

    private func loadDuration(for item: AVPlayerItem) {
        guard #available(iOS 15.0, *) else {
            return
        }
        durationTask = Task { @MainActor [weak self, weak item] in
            guard let asset = item?.asset else { return }

            do {
                let durationTime = try await asset.load(.duration)
                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    let seconds = durationTime.seconds
                    duration = seconds.isFinite && seconds >= 0 ? seconds : 0
                    durationTask = nil
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    duration = 0
                    durationTask = nil
                }
            }
        }
    }

    private func observeCurrentTime() {
        timeObservationToken = audioPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: DispatchQueue.main
        ) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            guard seconds.isFinite else { return }
            MainActor.assumeIsolated {
                self.currentTime = seconds >= 0 ? seconds : 0
            }
        }
    }

    private func removeTimeObserver() {
        guard let timeObservationToken else { return }
        audioPlayer.removeTimeObserver(timeObservationToken)
        self.timeObservationToken = nil
    }

    private func resetProgress() {
        duration = 0
        currentTime = 0
    }

    private func resetForIdleState() {
        durationTask?.cancel()
        durationTask = nil
        removeTimeObserver()
        resetProgress()
        audioPlayer.pause()
        audioPlayer.replaceCurrentItem(with: nil)
        looper = nil
        status = .idle
    }
}
