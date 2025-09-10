//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Store {

    struct Dispatcher: Sendable {

        typealias Handler = @Sendable(Namespace.Action, StoreDelay, StaticString, StaticString, UInt) -> Void
        private let handler: Handler

        init(_ store: Store) {
            handler = { [weak store] in
                store?.dispatch(
                    $0,
                    delay: $1,
                    file: $2,
                    function: $3,
                    line: $4
                )
            }
        }

        init(_ handler: @escaping Handler) {
            self.handler = handler
        }

        func dispatch(
            _ action: Namespace.Action,
            delay: StoreDelay = .none(),
            file: StaticString = #file,
            function: StaticString = #function,
            line: UInt = #line
        ) {
            handler(
                action,
                delay,
                file,
                function,
                line
            )
        }
    }
}
