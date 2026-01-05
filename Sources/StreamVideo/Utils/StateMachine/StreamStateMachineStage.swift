//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol that defines a stage in a state machine.
public protocol StreamStateMachineStage: CustomStringConvertible {
    /// The type of the stage's unique identifier, conforming to `Hashable`.
    associatedtype ID: Hashable
    /// A type alias for the transition function.
    typealias Transition = (Self) throws -> Void
    /// The unique identifier of the stage.
    var id: ID { get }

    var container: String { get }
    /// The transition function that handles the transition logic.
    var transition: Transition? { get set }

    func willTransitionAway()

    /// Defines the transition logic from a previous stage to the current stage.
    ///
    /// - Parameter previousStage: The previous stage.
    /// - Returns: The new stage if the transition is allowed, `nil` otherwise.
    func transition(from previousStage: Self) -> Self?

    func didTransitionAway()
}

/// An extension to provide a default description for stages.
extension StreamStateMachineStage {
    /// A textual representation of the stage, combining the type and identifier.
    public var description: String { "\(container):\(type(of: self)):\(id)" }
}
