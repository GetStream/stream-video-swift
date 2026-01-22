//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

final class StreamSnapshotTrigger: SnapshotTriggering, @unchecked Sendable {
    lazy var binding: Binding<Bool> = Binding<Bool>(
        get: { [weak self] in
            self?.currentValueSubject.value ?? false
        },
        set: { [weak self] in
            self?.currentValueSubject.send($0)
        }
    )

    var publisher: AnyPublisher<Bool, Never> { currentValueSubject.eraseToAnyPublisher() }

    private let currentValueSubject = CurrentValueSubject<Bool, Never>(false)

    init() {}

    func capture() {
        binding.wrappedValue = true
    }
}

/// Provides the default value of the `StreamSnapshotTrigger` class.
struct StreamSnapshotTriggerKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamSnapshotTrigger = .init()
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
