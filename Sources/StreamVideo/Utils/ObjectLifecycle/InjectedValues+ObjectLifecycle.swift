//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension InjectedValues {
    /// Lifecycle observer used by tracked SDK objects.
    var objectLifecycleObserver: ObjectLifecycle.Observing {
        get { Self[ObjectLifecycle.ObserverKey.self] }
        set { Self[ObjectLifecycle.ObserverKey.self] = newValue }
    }
}
