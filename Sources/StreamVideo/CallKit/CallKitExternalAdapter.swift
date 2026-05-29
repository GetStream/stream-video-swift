//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Mirrors SDK-owned call state into CallKit when the user starts or accepts
/// a call from the app UI instead of from CallKit's system UI.
///
/// `CallKitService` already owns calls that originate from VoIP pushes because
/// those calls enter the SDK through `CXProvider.reportNewIncomingCall`. In-app
/// flows are different: the SDK first sees a regular `Call` state transition
/// (`ringingCall` or `activeCall`) and CallKit has to be told afterwards that
/// the same call is now system-managed. This adapter observes the two pieces of
/// SDK state that describe that transition and asks `CallKitService` to perform
/// the matching CallKit handoff.
///
/// The adapter is intentionally internal. Public apps configure CallKit through
/// `CallKitAdapter`; this type is a small bridge used by that adapter once a
/// `StreamVideo` instance is available.
final class CallKitExternalAdapter: @unchecked Sendable {

    /// Snapshot of the two SDK-level call references that matter to external
    /// CallKit handoff.
    ///
    /// A ringing outgoing call means CallKit should receive a
    /// `CXStartCallAction`. A ringing call that later becomes the active call
    /// means CallKit should be told that the outgoing call connected. For
    /// incoming calls, the accepting stage asks `CallKitService` directly
    /// because it already has a CallKit UUID from the incoming ring report.
    private struct State: Equatable {
        /// Call currently owned by the SDK as an established call.
        var activeCall: Call?
        /// Call currently ringing in the SDK, either incoming or outgoing.
        var ringingCall: Call?

        /// Compares call identity only.
        ///
        /// `Call` instances publish a lot of mutable state. The handoff logic
        /// only cares when the active or ringing call identity changes, so
        /// comparing `cId` avoids re-running CallKit transactions for unrelated
        /// participant, settings, or statistics updates.
        static func == (
            lhs: CallKitExternalAdapter.State,
            rhs: CallKitExternalAdapter.State
        ) -> Bool {
            lhs.activeCall?.cId == rhs.activeCall?.cId
                && lhs.ringingCall?.cId == rhs.ringingCall?.cId
        }
    }

    @Injected(\.callKitService) private var callKitService
    @Injected(\.currentDevice) private var currentDevice

    /// Stream client whose call state should be mirrored to CallKit.
    ///
    /// `CallKitAdapter` updates this whenever the app logs in or logs out. A
    /// new value tears down the old Combine subscriptions before installing new
    /// ones so handoff decisions always belong to the current authenticated
    /// user.
    var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    private let disposableBag = DisposableBag()
    private var state: State = .init()

    // MARK: - Private Helpers

    /// Rebuilds observation for the current `StreamVideo` client.
    ///
    /// The adapter is disabled on simulator for parity with the rest of the
    /// CallKit stack. On devices, it observes both active and ringing call
    /// publishers together so transitions are evaluated from a consistent
    /// pair of values. State handling ultimately hops to the main actor because
    /// `CallState` is main-actor isolated and the handoff checks read values
    /// such as `createdBy`.
    private func didUpdate(_ streamVideo: StreamVideo?) {
        disposableBag.removeAll()

        guard
            let streamVideo,
            currentDevice.deviceType != .simulator
        else {
            return
        }

        let activeCallPublisher = streamVideo
            .state
            .$activeCall
        let ringingCallPublisher = streamVideo
            .state
            .$ringingCall

        Publishers
            .CombineLatest(activeCallPublisher, ringingCallPublisher)
            .map { State(activeCall: $0, ringingCall: $1) }
            .removeDuplicates()
            .log(.debug, subsystems: .callKit) {
                "State updated { activeCallCiD:\($0.activeCall?.cId ?? "-"), ringingCallCiD:\($0.ringingCall?.cId ?? "-") }"
            }
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in await self?.didUpdate($0) }
            .store(in: disposableBag)
    }

    /// Applies one SDK state snapshot to the CallKit bridge.
    ///
    /// Outgoing call handoff happens in two phases:
    /// 1. The local user creates/rings a call, which publishes a new
    ///    `ringingCall`. That is the earliest point where CallKit can be asked
    ///    to start an outgoing system call.
    /// 2. The same call becomes `activeCall` and the previous ringing value is
    ///    cleared. That is the point where CallKit can be told the outgoing call
    ///    connected.
    ///
    /// Both checks verify that the call was created by the current user. This
    /// prevents the external outgoing bridge from handling incoming calls, which
    /// already have their own CallKit lifecycle through VoIP push reporting.
    @MainActor
    private func didUpdate(_ newState: State) async {
        if
            let newActiveCall = newState.activeCall,
            state.ringingCall?.cId == newActiveCall.cId,
            newState.ringingCall == nil,
            newActiveCall.state.createdBy?.id == streamVideo?.user.id {
            await log.throwing(subsystems: .callKit) {
                await callKitService.reportExternalConnectedOutgoingCall(
                    newActiveCall
                )
            }
        } else if
            let newRingingCall = newState.ringingCall,
            state.ringingCall == nil,
            state.activeCall == nil,
            newRingingCall.state.createdBy?.id == streamVideo?.user.id {
            await log.throwing(subsystems: .callKit) {
                try await callKitService.reportExternalOutgoingCall(
                    newRingingCall
                )
            }
        }

        self.state = newState
    }
}

extension CallKitExternalAdapter: InjectionKey {
    /// Provides the current external CallKit bridge.
    nonisolated(unsafe) static var currentValue: CallKitExternalAdapter = .init()
}

extension InjectedValues {
    /// Accessor for the internal adapter that mirrors in-app call flows to
    /// CallKit.
    var callKitExternalAdapter: CallKitExternalAdapter {
        get { Self[CallKitExternalAdapter.self] }
        set { Self[CallKitExternalAdapter.self] = newValue }
    }
}
