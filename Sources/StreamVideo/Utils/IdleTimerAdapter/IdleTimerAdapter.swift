//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// swiftlint:disable discourage_task_init

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class IdleTimerAdapter: @unchecked Sendable {

    private var observationCancellable: AnyCancellable?
    private(set) var isIdleTimerDisabled: Bool = false

    convenience init(_ streamVideo: StreamVideo) {
        self.init(streamVideo.state.$activeCall.eraseToAnyPublisher())
    }

    init(_ publisher: AnyPublisher<Call?, Never>) {
        #if canImport(UIKit)
        Task { @MainActor in
            self.isIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        }
        observationCancellable = publisher
            .map { $0 != nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasActiveCall in
                MainActor.assumeIsolated { [weak self] in
                    UIApplication.shared.isIdleTimerDisabled = hasActiveCall
                    self?.isIdleTimerDisabled = hasActiveCall
                }
            }
        #endif
    }

    deinit {
        #if canImport(UIKit)
        Task { @MainActor in UIApplication.shared.isIdleTimerDisabled = false }
        #endif
    }
}
