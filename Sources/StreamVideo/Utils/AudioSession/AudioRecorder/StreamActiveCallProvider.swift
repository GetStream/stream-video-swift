//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol defining an object that can provide information regarding an active call.
protocol StreamActiveCallProviding {
    var hasActiveCallPublisher: AnyPublisher<Bool, Never> { get }
}

extension StreamVideo: StreamActiveCallProviding {
    var hasActiveCallPublisher: AnyPublisher<Bool, Never> {
        state
            .$activeCall
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
}

/// Provides the default value of the `StreamActiveCallProviding` class.
struct StreamActiveCallProviderKey: InjectionKey {
    static var currentValue: StreamActiveCallProviding?
}

extension InjectedValues {
    var activeCallProvider: StreamActiveCallProviding {
        get {
            Self[StreamActiveCallProviderKey.self]!
        }
        set {
            Self[StreamActiveCallProviderKey.self] = newValue
        }
    }
}
