//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight, sendable facade used to dispatch actions back to a
/// ``Store``.
///
/// `Dispatcher` abstracts how actions are forwarded to the store. It’s
/// primarily intended for use inside middleware so side effects can issue
/// follow‑up actions without holding a strong reference to the store.
///
/// - Note: Supports dispatching either raw actions with an optional
///   ``StoreDelay`` or preboxed actions via ``StoreActionBox``.

extension Store {

    struct Dispatcher: Sendable {

        // MARK: - Types

        /// Low‑level dispatch closure used internally.
        typealias Handler = @Sendable (
            [StoreActionBox<Namespace.Action>],
            StaticString,
            StaticString,
            UInt
        ) -> Void
        private let handler: Handler

        // MARK: - Initialization

        /// Creates a dispatcher bound to a specific store.
        ///
        /// - Parameter store: The store that should receive dispatched
        ///   actions.
        init(_ store: Store) {
            handler = { [weak store] in
                store?.dispatch(
                    $0,
                    file: $1,
                    function: $2,
                    line: $3
                )
            }
        }

        /// Creates a dispatcher with a custom handler.
        ///
        /// Useful for testing and advanced scenarios.
        init(_ handler: @escaping Handler) {
            self.handler = handler
        }

        // MARK: - Dispatch

        /// Dispatches an array of boxed actions (optionally delayed).
        ///
        /// - Parameters:
        ///   - actions: The boxed actions to dispatch.
        ///   - file: Source file (auto‑captured).
        ///   - function: Function name (auto‑captured).
        ///   - line: Line number (auto‑captured).
        func dispatch(
            _ actions: [StoreActionBox<Namespace.Action>],
            file: StaticString = #file,
            function: StaticString = #function,
            line: UInt = #line
        ) {
            handler(
                actions,
                file,
                function,
                line
            )
        }

        /// Dispatches a single raw action with an optional delay.
        ///
        /// - Parameters:
        ///   - action: The action to dispatch.
        ///   - delay: Optional delay configuration.
        ///   - file: Source file (auto‑captured).
        ///   - function: Function name (auto‑captured).
        ///   - line: Line number (auto‑captured).
        func dispatch(
            _ action: Namespace.Action,
            delay: StoreDelay? = nil,
            file: StaticString = #file,
            function: StaticString = #function,
            line: UInt = #line
        ) {
            handler(
                [actionBox(action, delay: delay)],
                file,
                function,
                line
            )
        }

        // MARK: - Private Helpers

        private func actionBox(
            _ action: Namespace.Action,
            delay: StoreDelay?
        ) -> StoreActionBox<Namespace.Action> {
            guard
                let delay
            else {
                return .normal(action)
            }
            return .delayed(action, delay: delay)
        }
    }
}
