//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

extension BatteryStore.Namespace {

    /// Observes UIKit battery notifications and forwards updates to the store.
    final class ObservationMiddleware: Middleware<BatteryStore.Namespace>, @unchecked Sendable {

        private let disposableBag = DisposableBag()

        /// Initializes the middleware and sets up interruption monitoring.
        override init() {
            super.init()

            #if canImport(UIKit)
            NotificationCenter
                .default
                .publisher(for: UIDevice.batteryStateDidChangeNotification)
                .receive(on: DispatchQueue.main)
                .map { _ in MainActor.assumeIsolated { UIDevice.current.batteryState } }
                .sink { [weak self] in self?.dispatcher?.dispatch(.setState(.init($0))) }
                .store(in: disposableBag)

            NotificationCenter
                .default
                .publisher(for: UIDevice.batteryLevelDidChangeNotification)
                .receive(on: DispatchQueue.main)
                .map { _ in MainActor.assumeIsolated { UIDevice.current.batteryLevel } }
                .sink { [weak self] in self?.dispatcher?.dispatch(.setLevel($0)) }
                .store(in: disposableBag)
            #endif
        }
    }
}
