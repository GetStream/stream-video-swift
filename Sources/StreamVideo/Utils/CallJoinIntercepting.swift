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

    /// Notifies the interceptor that the SDK has started preparing the call for
    /// a join.
    ///
    /// This fires as soon as the underlying WebRTC state machine enters its
    /// `.joining` stage, before the peer connection has finished negotiating.
    /// Use it to apply setup that should be in place while the call is
    /// connecting — for example muting remote media or tweaking local call
    /// settings — so the user is never exposed to a half-connected experience.
    ///
    /// The hook is best-effort: the SDK does not wait for it before continuing
    /// to negotiate the call.
    ///
    /// - Parameter call: The call that is being prepared for joining.
    func callWillJoin(_ call: Call) async

    /// Performs application-specific work before the SDK completes a call join.
    ///
    /// Return normally to let the call continue into the joined state. Throw an
    /// error to abort the join flow and surface that failure back to the
    /// original join caller.
    ///
    /// - Parameter call: The call whose join response has already been applied
    ///   to local state and is about to become active.
    func callReadyToJoin(_ call: Call) async throws

    /// Notifies the interceptor that the call has fully transitioned into the
    /// joined state.
    ///
    /// This is the counterpart to ``callWillJoin(_:)`` and is the right place
    /// to undo any temporary setup applied while the call was connecting — for
    /// example restoring remote media that was muted during preparation.
    ///
    /// Like ``callWillJoin(_:)`` it is best-effort and does not block the
    /// call lifecycle.
    ///
    /// - Parameter call: The call that just became active.
    func callDidJoin(_ call: Call) async
}

/// Default no-op implementations that make the will-join and did-join hooks
/// optional.
///
/// Only ``CallJoinIntercepting/callReadyToJoin(_:)`` must be implemented.
/// Integrators that don't need to react to the will-join or did-join
/// transitions can omit these methods, and the additions stay source-compatible
/// with existing conformers.
extension CallJoinIntercepting {

    public func callWillJoin(_ call: Call) async { /* No-op by default. */ }

    public func callDidJoin(_ call: Call) async { /* No-op by default. */ }
}

extension WebRTCTrace {
    /// Creates a trace entry for a join interception failure.
    ///
    /// - Parameter error: The wrapped interception error that terminated the
    ///   join flow.
    init(
        _ error: CallJoinInterceptionError
    ) {
        let redactedError = error.underlyingError ?? error
        self.init(
            id: nil,
            tag: "call.join.interception.failed",
            data: .init([
                "error": String(describing: redactedError)
            ])
        )
    }
}
