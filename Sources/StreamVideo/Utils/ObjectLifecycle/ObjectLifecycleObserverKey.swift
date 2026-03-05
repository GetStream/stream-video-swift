//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ObjectLifecycle {
    /// Dependency injection key for the lifecycle observer.
    enum ObserverKey: InjectionKey {
        /// Active lifecycle observer dependency.
        nonisolated(unsafe) static var currentValue: Observing = {
            #if STEAM_TESTS
            CompositeObserver(
                LogObserver(subsystem: .lifecycle),
                Recorder()
            )
            #else
            CompositeObserver(LogObserver(subsystem: .lifecycle))
            #endif
        }()
    }
}
