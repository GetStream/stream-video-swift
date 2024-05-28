//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

protocol UUIDProviding {
    func get() -> UUID
}

enum UUIDProviderKey: InjectionKey {
    static var currentValue: UUIDProviding = StreamUUIDFactory()
}

extension InjectedValues {
    var uuidFactory: UUIDProviding {
        get { Self[UUIDProviderKey.self] }
        set { Self[UUIDProviderKey.self] = newValue }
    }
}

struct StreamUUIDFactory: UUIDProviding {
    func get() -> UUID { .init() }
}
