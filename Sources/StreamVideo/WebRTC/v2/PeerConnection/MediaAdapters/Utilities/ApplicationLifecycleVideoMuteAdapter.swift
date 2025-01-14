//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

final class ApplicationLifecycleVideoMuteAdapter {

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    private let sessionID: String
    private let sfuAdapter: SFUAdapter
    private let disposableBag = DisposableBag()

    init(
        sessionID: String,
        sfuAdapter: SFUAdapter
    ) {
        self.sessionID = sessionID
        self.sfuAdapter = sfuAdapter
    }

    func didUpdateCallSettings(_ callSettings: CallSettings) {
        guard !callSettings.videoOn else {
            return
        }
        disposableBag.removeAll()
    }

    func didStartCapturing(with capturer: StreamVideoCapturing) async {
        guard await capturer.supportsBackgrounding() == false else {
            return
        }
        applicationStateAdapter
            .$state
            .filter { $0 == .background }
            .sinkTask { [weak sfuAdapter, sessionID] _ in
                try await sfuAdapter?.updateTrackMuteState(
                    .video,
                    isMuted: true,
                    for: sessionID
                )
            }
            .store(in: disposableBag)

        applicationStateAdapter
            .$state
            .filter { $0 == .foreground }
            .sinkTask { [weak sfuAdapter, sessionID] _ in
                try await sfuAdapter?.updateTrackMuteState(
                    .video,
                    isMuted: false,
                    for: sessionID
                )
            }
            .store(in: disposableBag)
    }
}
