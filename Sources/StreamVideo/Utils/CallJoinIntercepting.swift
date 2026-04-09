//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An error emitted when a join interceptor prevents a call from finishing
/// its transition into the joined state.
///
/// The original reason is preserved in `underlyingError`, allowing integrators
/// to distinguish between their own domain error and an SDK-generated wrapper.
public final class CallJoinInterceptionError: ClientError, @unchecked Sendable {}

/// Allows integrators to inspect, delay, or veto the final step of joining a
/// call.
///
/// `Call.join(create:options:ring:notify:callSettings:policy:joinInterceptor:)`
/// invokes this interceptor after the backend join request has succeeded and
/// the local call state has been updated, but before the SDK marks the call as
/// active and completes the join flow.
public protocol CallJoinIntercepting: Sendable {

    /// Performs application-specific work before the SDK completes a call join.
    ///
    /// Return normally to let the call continue into the joined state. Throw an
    /// error to abort the join flow and surface that failure back to the
    /// original join caller.
    ///
    /// - Parameter call: The call whose join response has already been applied
    ///   to local state and is about to become active.
    func callReadyToJoin(_ call: Call) async throws
}

extension WebRTCTrace {
    /// Creates a trace entry for a join interception failure.
    ///
    /// - Parameter error: The wrapped interception error that terminated the
    ///   join flow.
    init(
        _ error: CallJoinInterceptionError
    ) {
        self.init(
            id: nil,
            tag: "call.join.interception.failed",
            data: .init(["error": "\(error)"])
        )
    }
}
