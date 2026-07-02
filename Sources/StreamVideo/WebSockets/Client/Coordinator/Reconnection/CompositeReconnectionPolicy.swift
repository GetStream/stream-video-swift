//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Combines child policies with a logical `and`/`or`.
///
/// - TODO: [StreamCore migration] Delete this and reuse StreamCore's own
///   `CompositeReconnectionPolicy` once StreamCore makes it `public`.
///   Currently `internal`, so re-implemented here. Logic is identical.
struct CompositeReconnectionPolicy: StreamCore.AutomaticReconnectionPolicy {
    enum Operator { case and, or }

    private let `operator`: Operator
    private let policies: [StreamCore.AutomaticReconnectionPolicy]

    init(_ operator: Operator, policies: [StreamCore.AutomaticReconnectionPolicy]) {
        self.operator = `operator`
        self.policies = policies
    }

    func canBeReconnected() -> Bool {
        switch `operator` {
        case .and:
            return policies.allSatisfy { $0.canBeReconnected() }
        case .or:
            return policies.contains { $0.canBeReconnected() }
        }
    }
}
