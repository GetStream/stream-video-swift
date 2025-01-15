//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// StreamPictureInPictureTrackStateAdapter serves as an adapter for managing the state of a video track
/// used for picture-in-picture functionality. It can enable or disable observers based on its isEnabled property
/// and ensures that the active track is always enabled when necessary.
final class StreamPictureInPictureTrackStateAdapter {

    /// This property represents whether the adapter is enabled or not.
    var isEnabled: Bool = false {
        didSet {
            /// When the 'isEnabled' property changes, this didSet observer is called.
            /// It checks if the new value is different from the old value, and if so,
            /// it calls the 'enableObserver' function.
            guard isEnabled != oldValue else { return }
            enableObserver(isEnabled)
        }
    }

    /// This property represents the active RTCVideoTrack.
    var activeTrack: RTCVideoTrack? {
        didSet {
            /// When the 'activeTrack' property changes, this didSet observer is called.
            /// If the adapter is enabled and the new 'activeTrack' is different from the old one,
            /// it disables the old track (if it exists).
            if isEnabled, oldValue?.trackId != activeTrack?.trackId, let oldValue {
                oldValue.isEnabled = false
                log.info(
                    "⚙️ Previously active track:\(oldValue.trackId) for picture-in-picture will be disabled now.",
                    subsystems: .pictureInPicture
                )
            }
        }
    }

    deinit {
        observerCancellable?.cancel()
    }

    // MARK: - Private helpers

    /// This property holds a reference to the observer cancellable.
    private var observerCancellable: AnyCancellable?

    /// This private function enables or disables an observer based on the 'isActive' parameter.
    ///
    /// - Parameter isActive: A Boolean value indicating whether the observer should be active.
    private func enableObserver(_ isActive: Bool) {
        observerCancellable?.cancel()
        observerCancellable = nil
        if isActive {
            /// If 'isActive' is true, it sets up an observer that checks tracks state periodically.
            observerCancellable = Timer
                .publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.checkTracksState()
                }
            log.debug("✅ Activated.", subsystems: .pictureInPicture)
        } else {
            /// If 'isActive' is false, it cancels the observer.
            log.debug("❌ Disabled.", subsystems: .pictureInPicture)
        }
    }

    /// This private function checks the state of the active track and enables it if it's not already enabled.
    private func checkTracksState() {
        let activeTrack = self.activeTrack
        if let activeTrack, !activeTrack.isEnabled {
            log.info(
                "⚙️ Active track:\(activeTrack.trackId) for picture-in-picture will be enabled now.",
                subsystems: .pictureInPicture
            )
            activeTrack.isEnabled = true
        }
    }
}
