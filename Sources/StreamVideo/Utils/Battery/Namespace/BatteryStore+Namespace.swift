//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension BatteryStore {

    /// Namespace configuration for the battery monitoring store.
    enum Namespace: StoreNamespace {

        /// The state type for this store namespace.
        typealias State = StoreState

        /// The action type for this store namespace.
        typealias Action = StoreAction

        /// Unique identifier for this store instance.
        ///
        /// Used for logging and debugging purposes.
        static let identifier: String = "battery.store"

        static func reducers() -> [Reducer<Namespace>] {
            [
                DefaultReducer()
            ]
        }

        static func middleware() -> [Middleware<BatteryStore.Namespace>] {
            [
                ObservationMiddleware()
            ]
        }
    }
}
