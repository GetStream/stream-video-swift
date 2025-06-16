//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif

final class ScreenIdleTimerAdapter {
    @Injected(\.activeCallProvider) private var activeCallProvider
    private let disposableBag = DisposableBag()

    init() {
        #if canImport(UIKit)
        activeCallProvider
            .hasActiveCallPublisher
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdate($0) }
            .store(in: disposableBag)
        #endif
    }

    private func didUpdate(_ hasActiveCall: Bool) {
        #if canImport(UIKit)
        Task { @MainActor in
            UIApplication.shared.isIdleTimerDisabled = hasActiveCall
        }
        #endif
    }
}
