//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecording {
    final class ApplicationStateMiddleware: Middleware<CallAudioRecording>, @unchecked Sendable {
        @Injected(\.applicationStateAdapter) private var applicationStateAdapter

        private let disposableBag = DisposableBag()
        private var activeCallCancellable: AnyCancellable?
        private var callSettingsCancellable: AnyCancellable?

        override init() {
            super.init()

            activeCallCancellable = applicationStateAdapter
                .statePublisher
                .sinkTask(storeIn: disposableBag) { [weak self] in await self?.didUpdate($0) }
        }

        // MARK: - Private Helpers

        private func didUpdate(_ applicationState: ApplicationState) async {
            guard state?.isRecording == true else {
                return
            }

            dispatcher?(.setIsRecording(false))
            try? await Task.sleep(nanoseconds: 250_000_000)
            dispatcher?(.setIsRecording(true))
        }
    }
}
