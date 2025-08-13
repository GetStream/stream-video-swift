//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecordingStore {

    final class ApplicationStateMiddleware: CallAudioRecordingMiddleware, @unchecked Sendable {
        @Injected(\.applicationStateAdapter) private var applicationStateAdapter

        private weak var store: CallAudioRecordingStore?

        private let disposableBag = DisposableBag()
        private var activeCallCancellable: AnyCancellable?
        private var callSettingsCancellable: AnyCancellable?

        init(_ store: CallAudioRecordingStore) {
            self.store = store

            activeCallCancellable = applicationStateAdapter
                .statePublisher
                .sinkTask(storeIn: disposableBag) { [weak self] in await self?.didUpdate($0) }
        }

        func apply(
            state: CallAudioRecordingStore.State,
            action: CallAudioRecordingAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            /* No-op */
        }

        // MARK: - Private Helpers

        private func didUpdate(_ applicationState: ApplicationState) async {
            guard store?.state.isRecording == true else {
                return
            }

            store?.dispatch(.setIsRecording(false))
            try? await Task.sleep(nanoseconds: 250_000_000)
            store?.dispatch(.setIsRecording(true))
        }
    }
}
