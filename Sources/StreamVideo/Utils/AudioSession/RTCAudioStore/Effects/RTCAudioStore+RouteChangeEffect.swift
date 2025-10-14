//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// An effect handler that listens for audio session route changes and updates call
    /// settings as needed.
    ///
    /// This class observes changes in the audio route (such as switching between speaker,
    /// Bluetooth, or headphones) and ensures the app's call settings stay in sync with the
    /// current audio configuration.
    final class RouteChangeEffect: NSObject, RTCAudioSessionDelegate {

        /// The device being used, injected for device-specific route handling.
        @Injected(\.currentDevice) private var currentDevice

        /// The audio session being observed for route changes.
        private let session: AudioSessionProtocol
        /// The RTCAudioStore being updated on route change events.
        private weak var store: RTCAudioStore?
        /// Delegate for notifying about call settings changes.
        private weak var delegate: StreamAudioSessionAdapterDelegate?
        /// Tracks the current call settings subscription.
        private var callSettingsCancellable: AnyCancellable?
        /// The most recent active call settings for route change comparison.
        private var activeCallSettings: CallSettings?

        /// Initializes the effect, sets up the route change observer, and subscribes to call settings.
        ///
        /// - Parameters:
        ///   - store: The audio store to update on changes.
        ///   - callSettingsPublisher: Publishes the latest call settings.
        ///   - delegate: Delegate for updating call settings in response to route changes.
        init(
            _ store: RTCAudioStore,
            callSettingsPublisher: AnyPublisher<CallSettings, Never>,
            delegate: StreamAudioSessionAdapterDelegate
        ) {
            session = store.session
            self.store = store
            self.delegate = delegate
            super.init()

            callSettingsCancellable = callSettingsPublisher
                .removeDuplicates()
                .dropFirst() // We drop the first one as we allow on init the CallAudioSession to configure as expected.
                .sink { [weak self] in self?.activeCallSettings = $0 }
            session.add(self)
        }

        deinit {
            session.remove(self)
        }

        // MARK: - RTCAudioSessionDelegate

        /// Handles audio route changes and updates call settings if the speaker state
        /// has changed compared to the current configuration.
        ///
        /// - Parameters:
        ///   - session: The session where the route change occurred.
        ///   - reason: The reason for the route change.
        ///   - previousRoute: The previous audio route before the change.
        func audioSessionDidChangeRoute(
            _ session: RTCAudioSession,
            reason: AVAudioSession.RouteChangeReason,
            previousRoute: AVAudioSessionRouteDescription
        ) {
            guard let activeCallSettings else {
                return
            }

            /// We rewrite the reference to RTCAudioSession with our internal session in order to allow
            /// easier stubbing for tests. That's a safe operation as our internal session is already pointing
            /// to the shared RTCAudioSession.
            let session = self.session

            guard currentDevice.deviceType == .phone else {
                if activeCallSettings.speakerOn != session.currentRoute.isSpeaker {
                    log.warning(
                        """
                        AudioSession didChangeRoute with speakerOn:\(session.currentRoute.isSpeaker)
                        while CallSettings have speakerOn:\(activeCallSettings.speakerOn).
                        We will update CallSettings to match the AudioSession's
                        current configuration
                        """,
                        subsystems: .audioSession
                    )
                    delegate?.audioSessionAdapterDidUpdateSpeakerOn(
                        session.currentRoute.isSpeaker
                    )
                }
                return
            }

            switch (activeCallSettings.speakerOn, session.currentRoute.isSpeaker) {
            case (true, false):
                delegate?.audioSessionAdapterDidUpdateSpeakerOn(
                    false
                )

            case (false, true) where session.category == AVAudioSession.Category.playAndRecord.rawValue:
                delegate?.audioSessionAdapterDidUpdateSpeakerOn(
                    true
                )

            default:
                break
            }
        }
    }
}
