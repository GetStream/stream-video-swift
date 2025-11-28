//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Base type for async side-effects that observe the store and can dispatch
/// follow-up actions without touching reducers directly.
class StoreEffect<Namespace: StoreNamespace>: @unchecked Sendable, Hashable {
    private lazy var identifier = "store.\(type(of: self))"

    /// Closure for dispatching new actions to the store.
    ///
    /// Use this to trigger additional actions in response to the current
    /// action. The dispatcher is automatically set when the middleware is
    /// added to a store.
    ///
    /// - Warning: Avoid creating infinite loops by dispatching actions
    ///   that trigger the same middleware repeatedly.
    var dispatcher: Store<Namespace>.Dispatcher?

    /// Closure for accessing the current store state.
    ///
    /// This provider is automatically set when the middleware is added to
    /// a store. It returns the current state at the time of access.
    var stateProvider: (() -> Namespace.State?)?

    /// The current store state, if available.
    ///
    /// Returns `nil` if the middleware hasn't been added to a store yet.
    /// Use this property to make decisions based on the current state.
    var state: Namespace.State? { stateProvider?() }

    /// Supplies the state publisher once the effect is attached to a store,
    /// giving subclasses a hook to start or stop their observations.
    func set(statePublisher: AnyPublisher<Namespace.State, Never>?) {
        // No-op
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (
        lhs: StoreEffect<Namespace>,
        rhs: StoreEffect<Namespace>
    ) -> Bool {
        lhs.identifier == rhs.identifier && lhs === rhs
    }
}
