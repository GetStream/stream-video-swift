//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

/// Policy for handling CallKit calls when the app lacks microphone
/// permission in the background.
///
/// - `.none`: Do nothing.
/// - `.endCall`: Fail reporting the call with an error.
public enum CallKitMissingPermissionPolicy: CustomStringConvertible {

    /// Take no action if microphone permission is missing.
    case none

    /// End the call with an error when permission is missing in the
    /// background.
    case endCall

    /// Human readable description.
    public var description: String {
        switch self {
        case .none:
            return ".none"
        case .endCall:
            return ".endCall"
        }
    }

    /// Concrete implementation backing each case.
    var policy: CallKitMissingPermissionPolicyProtocol {
        switch self {
        case .none:
            return NoOp()
        case .endCall:
            return EndCall()
        }
    }
}
