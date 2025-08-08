//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStoreAction {

    /// Represents actions that can be performed within the RTCAudioStore to control audio behavior
    /// or timing.
    enum Generic {
        /// An action that introduces a delay for a specified number of seconds before proceeding with
        /// the next operation.
        case delay(seconds: TimeInterval)
    }
}
