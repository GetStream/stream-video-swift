//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamVideoSwiftUI

/// Demo interceptor that waits until another participant announces readiness
/// through a custom event before the local join flow finishes.
@MainActor
final class DemoCallJoinInterceptor: CallJoinIntercepting {
    @Injected(\.streamVideo) private var streamVideo

    private let disposableBag = DisposableBag()
    private var ringingCallCancellable: AnyCancellable?
    private var customEventCancellable: AnyCancellable?
    private let customEventKey: String
    private var currentUserID: String = ""

    private let hasOtherReadyParticipants: CurrentValueSubject<Bool, Never> = .init(false)

    /// Creates the interceptor and starts tracking the active ringing call.
    ///
    /// The readiness handshake is only meaningful for ringing (1:1/group)
    /// calls, so the interceptor observes `streamVideo.state.ringingCall` from
    /// construction. Each time the ringing call changes it (re)wires the
    /// custom-event observation in `didUpdate(ringingCall:)`. The current user
    /// id is cached here because it's used both to emit the local readiness
    /// marker and to ignore the marker echoed back from ourselves.
    ///
    /// - Parameter customEventKey: The custom-event key used to exchange the
    ///   readiness marker between participants.
    init(
        customEventKey: String = "participant.ready"
    ) {
        self.customEventKey = customEventKey

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentUserID = streamVideo.state.user.id
            self.ringingCallCancellable = streamVideo
                .state
                .$ringingCall
                .receive(on: DispatchQueue.main)
                .removeDuplicates { $0?.cId == $1?.cId }
                .sinkTask(storeIn: disposableBag) { @MainActor [weak self] ringingCall in
                    self?.didUpdate(ringingCall: ringingCall)
                }
        }
    }

    // MARK: - CallJoinIntercepting

    /// Mutes incoming media while the call is still connecting.
    ///
    /// Called by the SDK when the WebRTC layer enters its joining stage. The
    /// demo silences remote audio so the local user doesn't hear other
    /// participants until the readiness handshake completes and the call is
    /// fully joined, avoiding leaking audio during the "preparing" window.
    ///
    /// - Parameter call: The call being prepared for joining.
    func callWillJoin(_ call: Call) async {
        await disableMediaTracksAndCallSettings(call)
    }

    /// Sends the local readiness marker and waits until another participant
    /// sends the same signal.
    ///
    /// The demo intentionally ignores send and wait failures so the example
    /// never blocks the UI forever when the readiness handshake is unavailable.
    func callReadyToJoin(_ call: Call) async throws {
        // If the cancellable is nil it means that this call isn't a ringing
        // call and thus we take no action.
        guard customEventCancellable != nil else {
            return
        }

        do {
            try await call.sendCustomEvent([customEventKey: .string(currentUserID)])
            log.debug("Call presence event was sent for userId:\(currentUserID). Waiting for others.")
        } catch {
            log.error("Call presence event for userId:\(currentUserID) failed.", error: error)
        }

        _ = try? await hasOtherReadyParticipants
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .nextValue()
    }

    /// Restores incoming media once the call is fully joined.
    ///
    /// Counterpart to ``callWillJoin(_:)``. Called by the SDK after the call
    /// has transitioned into the joined state, it re-enables the remote audio
    /// that was muted during preparation and stops the deactivation observer so
    /// the user can finally hear the other participants.
    ///
    /// - Parameter call: The call that just became active.
    func callDidJoin(_ call: Call) async {
        await restoreMediaTracksAndCallSettings(call)
    }

    // MARK: - Private Helpers

    /// Rewires the readiness observation whenever the ringing call changes.
    ///
    /// Any previous observation is cancelled first so a stale subscription
    /// never leaks across calls. When a new ringing call is present, it
    /// subscribes to that call's custom events, keeps only the readiness marker
    /// emitted by *other* participants (filtering out our own echo), and flips
    /// `hasOtherReadyParticipants` to `true` — which is what
    /// ``callReadyToJoin(_:)`` is waiting on. When the ringing call becomes
    /// `nil` it simply leaves the observation cancelled.
    ///
    /// - Parameter ringingCall: The currently ringing call, or `nil` if none.
    private func didUpdate(ringingCall: Call?) {
        cancelCustomEventObservation()

        guard let ringingCall else {
            return
        }

        customEventCancellable = ringingCall
            .eventPublisher(for: CustomVideoEvent.self)
            .receive(on: DispatchQueue.main)
            .compactMap { [customEventKey] in $0.custom[customEventKey]?.stringValue }
            .filter { [currentUserID] in $0 != currentUserID }
            .log(LogLevel.debug) { "Call presence event was received for userID:\($0)" }
            .map { _ in true }
            .sinkTask(
                storeIn: disposableBag
            ) { @MainActor [weak self] didReceiveReadyParticipant in
                self?.hasOtherReadyParticipants.send(didReceiveReadyParticipant)
            }

        log.debug("Call presence events observation has started.")
    }

    /// Tears down the readiness observation and resets its state.
    ///
    /// Used when the ringing call changes or disappears. It cancels the custom
    /// event subscription and resets `hasOtherReadyParticipants` to `false` so
    /// a later join doesn't inherit a stale "ready" signal from a previous
    /// call. The early return keeps the call idempotent when nothing is active.
    private func cancelCustomEventObservation() {
        guard customEventCancellable != nil else {
            return
        }
        customEventCancellable?.cancel()
        customEventCancellable = nil
        hasOtherReadyParticipants.send(false)
        log.debug("Call presence events observation was cancelled.")
    }

    /// Continuously mutes remote participants' audio while preparing.
    ///
    /// A simple one-shot mute isn't enough: participants (and their audio
    /// tracks) can arrive after the join begins. This subscribes to the
    /// participants list and disables the audio track of every participant
    /// other than the local user as they appear, so newly published remote
    /// audio stays muted too. The subscription is keyed in the disposable bag
    /// so ``restoreMediaTracksAndCallSettings(_:)`` can stop it once joined.
    ///
    /// - Parameter call: The call whose remote audio should be muted.
    private func disableMediaTracksAndCallSettings(_ call: Call) async {
        let currentUser = call.state.localParticipant

        call
            .state
            .$participants
            .map { array in array.filter { $0.sessionId != currentUser?.sessionId } }
            .map { $0.compactMap { $0.audioTrack } }
            .filter { $0.isEmpty == false }
            .sink { $0.forEach { $0.isEnabled = false } }
            .store(in: disposableBag, key: "tracks-deactivation")
    }

    /// Re-enables remote participants' audio after the call has joined.
    ///
    /// Reverses ``disableMediaTracksAndCallSettings(_:)``: it turns the audio
    /// track of every remote participant back on for a one-time restore, then
    /// removes the keyed subscription that was muting newly arriving tracks so
    /// the demo stops interfering with normal call audio.
    ///
    /// - Parameter call: The call whose remote audio should be restored.
    private func restoreMediaTracksAndCallSettings(_ call: Call) async {
        let currentUser = call.state.localParticipant
        call
            .state
            .participants
            .filter { $0.sessionId != currentUser?.sessionId && $0.audioTrack != nil }
            .forEach { $0.audioTrack?.isEnabled = true }

        disposableBag.remove("tracks-deactivation")
    }
}
