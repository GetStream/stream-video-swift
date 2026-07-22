//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

/// Serialises the outcome of an outgoing ringing call so a caller hang-up
/// that lands *while* `create(ring:)` is still in flight is never lost.
///
/// Context: the caller starts a ringing call and hangs up almost
/// immediately. Hang-up rejects the call, but if that reject reaches
/// the backend before `create` has finished, there is no call to reject yet:
/// the reject fails and the call that `create` produces a moment later keeps
/// ringing on the callee's device with no cancel ever delivered.
///
/// The fix funnels the two competing outcomes — "create finished"
/// (``created()``) and "user hung up" (``rejected()``) — through one lock.
/// Exactly one of them wins the race; the loser is handed a typed error
/// telling it to perform the cancel instead. That turns an unlucky ordering
/// into a deterministic hand-off between the two call sites.
///
/// The transitions are a synchronous compare-and-set, so a plain lock is
/// enough — there is no work awaited while holding it. This governs only the
/// creation-vs-cancel handshake; runtime concerns such as auto-ending the
/// ring when the app backgrounds live in ``OutgoingRingingController``.
final class OutgoingRingCreationCoordinator: @unchecked Sendable {
    /// Thrown from ``created()`` when the call was hung up before it finished
    /// being created. The create call site catches this and issues the cancel
    /// itself, now that the call actually exists on the backend to be rejected.
    struct CallAlreadyRejected: Error {}

    /// Thrown from ``rejected()`` when hang-up arrives before create completes.
    /// The hang-up call site catches this and skips its own reject, because the
    /// still-pending ``created()`` will perform the cancel once create returns.
    struct CallNotCreatedYet: Error {}

    /// Progress of the outgoing ring as observed by the two call sites.
    /// Starts at `.creating`. `.pendingCancel` records a hang-up that arrived
    /// while create was still running, so ``created()`` — and only it — issues
    /// the cancel once the call exists. `.rejected` is a hang-up that landed
    /// after create finished, where the hang-up site rejects directly.
    private enum State { case creating, created, pendingCancel, rejected }

    /// The call whose create/hang-up race we are arbitrating. Held so a future
    /// extension could reject from here; today the cancel is issued by the
    /// call sites that catch the errors above.
    private let call: Call

    /// Guards `state` so ``created()`` and ``rejected()`` observe and mutate it
    /// atomically and can never interleave. Held only across the synchronous
    /// compare-and-set below, so an unfair lock is the cheapest fit.
    private let lock = UnfairQueue()

    /// Only ever read or written inside `lock.sync`, which is what makes the
    /// unchecked `Sendable` conformance safe.
    private var state: State = .creating

    init(_ call: Call) {
        self.call = call
    }

    /// Records that `create(ring:)` returned successfully.
    ///
    /// - Throws: ``CallAlreadyRejected`` if a hang-up already ran while create
    ///   was in flight, signalling the caller to reject the now-created call so
    ///   the callee stops ringing.
    func created() throws {
        try lock.sync {
            // A hang-up landed while create was in flight but could not reject a
            // call that did not exist yet. Consume the pending cancel and tell
            // the create site to perform it, now that the call exists.
            guard state != .pendingCancel else {
                state = .rejected
                throw CallAlreadyRejected()
            }
            // Common path: no hang-up seen yet, so simply mark the call as
            // created and let the caller start the ring-timeout timer.
            state = .created
        }
    }

    /// Records that the caller hung up the outgoing ring.
    ///
    /// - Throws: ``CallNotCreatedYet`` if create has not finished yet,
    ///   signalling the caller to skip its reject; the pending ``created()``
    ///   will issue the cancel once create returns.
    func rejected() throws {
        try lock.sync {
            switch state {
            case .creating, .pendingCancel:
                // Create is still in flight: record the intent to cancel and
                // tell every hang-up to stand down, so none fires a reject the
                // backend would refuse for a not-yet-created call. ``created()``
                // performs the single cancel once create returns.
                state = .pendingCancel
                throw CallNotCreatedYet()
            case .created, .rejected:
                // Create already finished: record the rejection and let the
                // hang-up site reject through the normal path.
                state = .rejected
            }
        }
    }
}
