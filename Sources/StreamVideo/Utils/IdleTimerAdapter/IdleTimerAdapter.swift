//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

// swiftlint:disable discourage_task_init

import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class IdleTimerAdapter: @unchecked Sendable {

    private(set) var isIdleTimerDisabled: Bool = false
    private let disposableBag = DisposableBag()

    init(_ streamVideo: StreamVideo) {
        #if canImport(UIKit)
        Task { @MainActor in
            self.isIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        }
        streamVideo
            .state
            .$activeCall
            .map { $0 != nil }
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.didUpdate(hasActiveCall: $0) }
            .store(in: disposableBag)
        #endif
    }

    // MARK: - Private helpers

    @MainActor
    private func didUpdate(hasActiveCall: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = hasActiveCall
        isIdleTimerDisabled = hasActiveCall
        #endif
    }
}
