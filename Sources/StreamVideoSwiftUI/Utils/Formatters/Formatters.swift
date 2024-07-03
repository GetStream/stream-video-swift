//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public class Formatters {
    public var mediaDuration: MediaDurationFormatter = StreamMediaDurationFormatter()
}

// MARK: - Formatters + Injection

/// Provides the default value of the `Formatters` class.
#if swift(>=6.0)
enum FormattersKey: @preconcurrency InjectionKey {
    @MainActor static var currentValue: Formatters = .init()
}
#else
enum FormattersKey: InjectionKey {
    @MainActor static var currentValue: Formatters = .init()
}
#endif

extension InjectedValues {
    /// Provides access to the `Formatters` class to the views and view models.
    public var formatters: Formatters {
        get {
            Self[FormattersKey.self]
        }
        set {
            Self[FormattersKey.self] = newValue
        }
    }
}
