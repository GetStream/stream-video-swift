//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An extension of `RejectCallRequest` that defines various reasons for rejecting a call.
extension RejectCallRequest {

    /// Enum containing possible reasons for rejecting a call.
    public enum Reason {

        /// Indicates that the callee is busy and cannot accept the call.
        public static let busy = "busy"

        /// Indicates that the callee intentionally declines the call.
        public static let decline = "decline"

        /// Indicates that the caller cancels the call.
        public static let cancel = "cancel"

        /// Indicates that the callee didn't answer the call in a given time amount.
        public static let timeout = "timeout"
    }
}
