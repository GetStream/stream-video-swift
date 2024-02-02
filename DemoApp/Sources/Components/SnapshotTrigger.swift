//
//  SnapshotTrigger.swift
//  StreamVideoSwiftUI
//
//  Created by Ilias Pavlidakis on 2/2/24.
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

