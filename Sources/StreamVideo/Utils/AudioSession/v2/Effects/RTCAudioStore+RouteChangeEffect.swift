//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    final class RouteChangeEffect: NSObject, RTCAudioSessionDelegate {

        @Injected(\.currentDevice) private var currentDevice

        private let session: RTCAudioSession
        private weak var store: RTCAudioStore?
        private weak var delegate: StreamAudioSessionAdapterDelegate?
        private var callSettingsCancellable: AnyCancellable?
        private var activeCallSettings: CallSettings?

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
                .sink { [weak self] in self?.activeCallSettings = $0 }
            session.add(self)
        }

        deinit {
            session.remove(self)
        }

        // MARK: - RTCAudioSessionDelegate

        func audioSessionDidChangeRoute(
            _ session: RTCAudioSession,
            reason: AVAudioSession.RouteChangeReason,
            previousRoute: AVAudioSessionRouteDescription
        ) {
            guard let activeCallSettings else {
                return
            }

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
                    delegate?.audioSessionAdapterDidUpdateCallSettings(
                        callSettings: activeCallSettings
                            .withUpdatedSpeakerState(session.currentRoute.isSpeaker)
                    )
                }
                return
            }

            switch (activeCallSettings.speakerOn, session.currentRoute.isSpeaker) {
            case (true, false):
                delegate?.audioSessionAdapterDidUpdateCallSettings(
                    callSettings: activeCallSettings.withUpdatedSpeakerState(false)
                )

            case (false, true) where session.category == AVAudioSession.Category.playAndRecord.rawValue:
                delegate?.audioSessionAdapterDidUpdateCallSettings(
                    callSettings: activeCallSettings.withUpdatedSpeakerState(true)
                )

            default:
                break
            }
        }
    }
}
