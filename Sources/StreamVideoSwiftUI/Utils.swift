//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public class Utils {
    public var userListProvider: UserListProvider?
    public var callSoundsPlayer: CallSoundsPlayer

    public init(
        userListProvider: UserListProvider? = nil,
        callSoundsPlayer: CallSoundsPlayer = .init()
    ) {
        self.userListProvider = userListProvider
        self.callSoundsPlayer = callSoundsPlayer
    }
}

// MARK: - Utils + Default

/// Provides the default value of the `Utils` class.
public enum UtilsKey: InjectionKey {
    public nonisolated(unsafe) static var currentValue: Utils = .init()
}

extension InjectedValues {
    /// Provides access to the `Utils` class to the views and view models.
    public var utils: Utils {
        get {
            Self[UtilsKey.self]
        }
        set {
            Self[UtilsKey.self] = newValue
        }
    }
}
