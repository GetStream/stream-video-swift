//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// The `AVPlayer` of an HLS call. ``Call/hlsPlayer()`` returns it.
///
/// It behaves like `AVPlayer`, and it can resume a live stream from the live
/// edge. A paused live stream falls behind, and its window can slide past the
/// paused position. Call `play()` on the main thread, like on `AVPlayer`.
///
/// The SDK resumes the player after the system paused it, for example when
/// the app returns to the foreground. It never resumes a player that you
/// paused with `pause()`.
///
/// Only ``Call/hlsPlayer()`` returns a player that the SDK manages: it mutes
/// with the audio output of the call, resumes after a system pause, and stops
/// when the call leaves HLS. A player that you create with an inherited
/// initializer is not managed. The live-edge seek belongs to `play()` and
/// ``playFromLiveEdge()``. Setting `rate` or calling `playImmediately(atRate:)`
/// does not seek.
///
/// - Important: This API is in beta, like ``PlaybackType``.
// Xcode 27 infers it from AVPlayer. An older SDK may not, and the call
// controller hands the player across actors.
public class HLSPlayer: AVPlayer, @unchecked Sendable {

    /// Whether `play()` restarts near the live edge.
    ///
    /// When `true`, `play()` on a stopped player first seeks to the
    /// recommended offset from the live edge, inside the seekable range. When
    /// `false`, `play()` continues where the stream stopped, like `AVPlayer`.
    /// The default is `true`.
    public var resumeFromLive: Bool = true

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    /// Whether the user paused the player. It changes on the main thread.
    private var isPausedByUser = false
    private var observers: [AnyCancellable] = []

    /// Plays the stream. Restarts near the live edge when ``resumeFromLive``
    /// is `true`, unless the player is already playing. A seek during
    /// playback would stall it.
    override public func play() {
        isPausedByUser = false
        if resumeFromLive, rate == 0 { seekToLiveEdge() }
        super.play()
    }

    /// Pauses the stream. The SDK keeps it paused when the system would
    /// resume it.
    override public func pause() {
        isPausedByUser = true
        super.pause()
    }

    /// Restarts near the live edge and plays, whatever ``resumeFromLive``
    /// says.
    public func playFromLiveEdge() {
        isPausedByUser = false
        seekToLiveEdge()
        super.play()
    }

    // MARK: - Internal

    /// Follows the pause state, the system, and the audio output.
    /// - Parameter audioOutputOn: Mutes the player while it is `false`. The
    ///   current value applies at once.
    func startObserving(audioOutputOn: AnyPublisher<Bool, Never>) {
        observers = [
            observeUserPauses(),
            observeSystemPauses(),
            audioOutputOn
                .removeDuplicates()
                .sink { [weak self] in self?.isMuted = !$0 }
        ]
    }

    /// Stops the observers and the stream. The player is not used again.
    func invalidate() {
        observers = []
        pause()
        replaceCurrentItem(with: nil)
    }

    // MARK: - Private Helpers

    /// Something other than the SDK can pause or play the player, for
    /// example the app or the Picture-in-Picture window. Treat it as the
    /// user's, so a later system resume does not undo it. The system's own
    /// pauses, such as an audio interruption, carry another reason. The
    /// resume of the SDK is a `play()` call too, and it only plays a player
    /// that the user did not pause, so it keeps the state.
    ///
    /// `pause()` and `play()` record the state themselves, which covers
    /// iOS 14 and earlier. This covers the calls that bypass them.
    private func observeUserPauses() -> AnyCancellable {
        guard #available(iOS 15.0, *) else { return AnyCancellable {} }
        return NotificationCenter.default
            .publisher(for: AVPlayer.rateDidChangeNotification, object: self)
            // The notification does not name a thread.
            .receive(on: DispatchQueue.main)
            .filter {
                ($0.userInfo?[AVPlayer.rateDidChangeReasonKey] as? String)
                    == AVPlayer.RateDidChangeReason.setRateCalled.rawValue
            }
            .sink { [weak self] _ in
                guard let self else { return }
                isPausedByUser = rate == 0
            }
    }

    /// iOS can pause a player without a user action, for example when the app
    /// goes to the background. Nothing resumes it afterwards, so resume it
    /// when the app becomes active, or an audio interruption ends with
    /// `.shouldResume`.
    private func observeSystemPauses() -> AnyCancellable {
        let appBecameActive = applicationStateAdapter
            .statePublisher
            .removeDuplicates()
            // Skip the value already in state.
            .dropFirst()
            .filter { $0 == .foreground }
            .map { _ in () }
        let interruptionEnded = NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .filter {
                let userInfo = $0.userInfo
                let type = (userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                    .flatMap(AVAudioSession.InterruptionType.init)
                let options = (userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .map(AVAudioSession.InterruptionOptions.init)
                return type == .ended && options?.contains(.shouldResume) == true
            }
            .map { _ in () }
        return appBecameActive
            .merge(with: interruptionEnded)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                // Read on the main thread, right before it acts, so a pause
                // that arrives in between is not undone.
                guard let self, !isPausedByUser, rate == 0 else { return }
                play()
            }
    }

    /// Seeks to the live edge. Does nothing when the item has no usable
    /// seekable range.
    private func seekToLiveEdge() {
        guard
            let item = currentItem,
            let range = item.seekableTimeRanges.last?.timeRangeValue,
            let target = liveEdgeTarget(
                in: range,
                recommendedOffset: item.recommendedTimeOffsetFromLive
            ) else { return }
        seek(to: target)
    }

    /// Where a resumed live stream starts: the recommended distance from the
    /// live edge, kept inside the seekable range.
    /// - Returns: `nil` when the range is not usable.
    private func liveEdgeTarget(
        in range: CMTimeRange,
        recommendedOffset: CMTime
    ) -> CMTime? {
        guard range.isValid, !range.isEmpty else { return nil }
        guard recommendedOffset.isNumeric else { return range.end }
        let target = CMTimeSubtract(range.end, recommendedOffset)
        return CMTimeMaximum(target, range.start)
    }
}
