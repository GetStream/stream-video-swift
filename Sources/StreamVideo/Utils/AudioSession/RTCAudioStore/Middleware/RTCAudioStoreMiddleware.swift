//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A middleware protocol for intercepting and handling actions applied to the RTCAudioStore state.
/// Implementers can observe or modify actions as they are processed, enabling custom behavior or side effects.
protocol RTCAudioStoreMiddleware: AnyObject {

    var store: RTCAudioStore? { get }

    /// Applies an action to the RTCAudioStore state, with context information.
    ///
    /// - Parameters:
    ///   - state: The current state of the RTCAudioStore.
    ///   - action: The action to be applied to the state.
    ///   - file: The source file from which the action originated.
    ///   - function: The function from which the action originated.
    ///   - line: The line number in the source file where the action originated.
    ///
    /// Use this method to observe or modify actions before they affect the state.
    func apply(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}
