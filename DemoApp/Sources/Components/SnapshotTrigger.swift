//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

 final class StreamSnapshotTrigger: ObservableObject {

    @Published var capture: Bool = false

    init() {}
}

/// Provides the default value of the `StreamSnapshotTrigger` class.
struct StreamSnapshotTriggerKey: InjectionKey {
    static var currentValue: StreamSnapshotTrigger = .init()
}

extension InjectedValues {
    /// Provides access to the `StreamSnapshotTrigger` class to the views and view models.
    var snapshotTrigger: StreamSnapshotTrigger {
        get {
            Self[StreamSnapshotTriggerKey.self]
        }
        set {
            Self[StreamSnapshotTriggerKey.self] = newValue
        }
    }
}

