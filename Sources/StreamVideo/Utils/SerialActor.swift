//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// `SerialActor` is an actor that serially enqueues and executes asynchronous blocks.
/// Use this actor to ensure serial execution of tasks in an asynchronous context.
actor SerialActor {

    /// Enqueues and executes the provided block asynchronously.
    /// - Parameter block: A `Sendable` asynchronous block that may throw errors.
    /// This block will be enqueued and executed by the actor.
    func enqueue(_ block: @Sendable @escaping () async throws -> Void) rethrows {
        Task {
            try await block()
        }
    }
}
