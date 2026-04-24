//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Call.StateMachine.Stage {

    /// Creates a leaving stage for the call state machine.
    ///
    /// - Parameters:
    ///   - context: The context containing necessary state.
    ///   - reason: Optional reason forwarded to the backend leave request.
    /// - Returns: A new `LeavingStage` instance.
    static func leaving(
        _ context: Context,
        reason: String?
    ) -> Call.StateMachine.Stage {
        LeavingStage(context, reason: reason)
    }
}

extension Call.StateMachine.Stage {

    /// Represents the leaving stage in the call state machine.
    final class LeavingStage: Call.StateMachine.Stage, @unchecked Sendable {
        private let reason: String?
        private let disposableBag = DisposableBag()
        /// When a replacement call leaves before it becomes `activeCall`, the
        /// previous active call may still be stored in `StreamVideo.State`.
        ///
        /// Clearing `activeCall` in that situation reuses
        /// `StreamVideo.State.didUpdateActiveCall`, which leaves the stale
        /// active call for us. This keeps the replacement flow consistent with
        /// the normal active-call handoff without affecting unrelated leaves.
        private var shouldCascadeActiveCallTeardown = false

        init(
            _ context: Context,
            reason: String?
        ) {
            self.reason = reason
            super.init(id: .leaving, context: context)
        }

        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .leaving:
                return nil
            default:
                shouldCascadeActiveCallTeardown = [
                    .accepting,
                    .accepted,
                    .joining
                ].contains(previousStage.id)
                execute()
                return self
            }
        }

        private func execute() {
            guard
                let call = context.call,
                case let .leaving(input) = context.input
            else {
                return
            }

            input.disposableBag.removeAll()
            input.callController.leave(reason: reason)
            input.closedCaptionsAdapter.stop()

            /// Upon `Call.leave` we remove the call from the cache. Any
            /// further actions that are required to happen on the call object
            /// (e.g. rejoin) will need to fetch a new instance from
            /// `StreamVideo`.
            input.callCache.remove(for: call.cId)
            input.resetOutgoingRingingController()
            input.resetAudioFilter()

            Task(disposableBag: disposableBag) { @MainActor [weak self, call] in
                guard let self else {
                    return
                }

                if call.streamVideo.state.ringingCall?.cId == call.cId {
                    call.streamVideo.state.ringingCall = nil
                }
                /// Replacement flows can leave while `activeCall` still points
                /// to the call being replaced. Resetting `activeCall` here
                /// triggers the existing `oldValue.leave()` cascade and tears
                /// down that stale active call as well.
                if let activeCall = call.streamVideo.state.activeCall,
                   activeCall.cId == call.cId || shouldCascadeActiveCallTeardown {
                    call.streamVideo.state.activeCall = nil
                }

                do {
                    try transition?(.idle(.init(call: call)))
                } catch {
                    log.error(error)
                }

                postNotification(with: CallNotification.callEnded, object: call)
            }
        }
    }
}
