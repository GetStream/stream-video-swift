//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension CallAudioRecordingStore {

    final class ActiveCallMiddleware: CallAudioRecordingMiddleware, @unchecked Sendable {
        @Injected(\.streamVideo) private var streamVideo

        private weak var store: CallAudioRecordingStore?

        private let disposableBag = DisposableBag()
        private var activeCallCancellable: AnyCancellable?
        private var callSettingsCancellable: AnyCancellable?

        init(_ store: CallAudioRecordingStore) {
            self.store = store

            activeCallCancellable = streamVideo
                .state
                .$activeCall
                .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in await self?.didUpdate($0) }
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

        private func didUpdate(_ activeCall: Call?) async {
            if let activeCall {
                callSettingsCancellable?.cancel()

                callSettingsCancellable = await activeCall
                    .state
                    .$callSettings
                    .map(\.audioOn)
                    .sink { [weak self] in self?.store?.dispatch(.setShouldRecord($0)) }
            } else {
                callSettingsCancellable?.cancel()
                callSettingsCancellable = nil
            }
        }
    }
}
