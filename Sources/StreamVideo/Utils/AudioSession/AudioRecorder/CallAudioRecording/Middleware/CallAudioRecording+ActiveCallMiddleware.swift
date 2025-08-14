//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecording {
    final class ActiveCallMiddleware: Middleware<CallAudioRecording>, @unchecked Sendable {
        @Injected(\.streamVideo) private var streamVideo

        private let disposableBag = DisposableBag()
        private var activeCallCancellable: AnyCancellable?
        private var callSettingsCancellable: AnyCancellable?

        override init() {
            super.init()

            activeCallCancellable = streamVideo
                .state
                .$activeCall
                .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in await self?.didUpdate($0) }
        }

        // MARK: - Private Helpers

        private func didUpdate(_ activeCall: Call?) async {
            if let activeCall {
                callSettingsCancellable?.cancel()

                callSettingsCancellable = await activeCall
                    .state
                    .$callSettings
                    .map(\.audioOn)
                    .sink { [weak self] in self?.dispatcher?(.setShouldRecord($0)) }
            } else {
                callSettingsCancellable?.cancel()
                callSettingsCancellable = nil
            }
        }
    }
}
