//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

class StoreExecutor<Namespace: StoreNamespace> {

    func run(
        identifier: String,
        state: Namespace.State,
        action: Namespace.Action,
        delayBefore: TimeInterval?,
        reducers: [Reducer<Namespace>],
        middleware: [Middleware<Namespace>],
        logger: StoreLogger<Namespace>,
        subject: CurrentValueSubject<Namespace.State, Never>,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws {
        if let delayBefore {
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * delayBefore))
        }

        middleware.forEach {
            $0.apply(
                state: state,
                action: action,
                file: file,
                function: function,
                line: line
            )
        }

        do {
            let updatedState = try reducers
                .reduce(state) {
                    try $1.reduce(
                        state: $0,
                        action: action,
                        file: file,
                        function: function,
                        line: line
                    )
                }

            logger.didComplete(
                identifier: identifier,
                action: action,
                state: updatedState,
                file: file,
                function: function,
                line: line
            )

            subject.send(updatedState)
        } catch {
            logger.didFail(
                identifier: identifier,
                action: action,
                error: error,
                file: file,
                function: function,
                line: line
            )
            throw error
        }
    }
}
