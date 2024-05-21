//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol StateMachineStage: CustomStringConvertible {
    associatedtype ID: Hashable
    typealias Transition = (Self) throws -> Void
    var id: ID { get }

    var transition: Transition? { get set }

    func transition(from previousStage: Self) -> Self?
}

extension StateMachineStage {
    public var description: String { "\(type(of: self)):\(id)" }
}
