//
//  StreamPictureInPictureTrackStateAdapter.swift
//  StreamVideoSwiftUI
//
//  Created by Ilias Pavlidakis on 9/1/24.
//

import Foundation
import StreamWebRTC
import Combine
import StreamVideo

final class StreamPictureInPictureTrackStateAdapter {
    
    var isEnabled: Bool = false {
        didSet {
            guard isEnabled != oldValue else { return }
            enableObserver(isEnabled)
        }
    }

    var activeTrack: RTCVideoTrack? {
        didSet {
            if isEnabled, oldValue?.trackId != activeTrack?.trackId {
                oldValue?.isEnabled = false
            }
        }
    }

    // MARK: - Private helpers

    private var observerCancellable: AnyCancellable?

    private func enableObserver(_ isActive: Bool) {
        if isActive {
            log.debug("Activating tracksAdapter!")
            observerCancellable = Timer
                .publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.checkTracksState() }
        } else {
            log.debug("Disabling tracksAdapter!")
            observerCancellable?.cancel()
            observerCancellable = nil
        }
    }

    private func checkTracksState() {
        if let activeTrack, !activeTrack.isEnabled {
            log.debug("Active track for Picture in Picture will be enabled now!")
            self.activeTrack?.isEnabled = true
        }
    }
}
