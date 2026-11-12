//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo

/// Joins, leaves, and replaces the livestream call.
/// The view calls these methods. It does not own the rules.
@MainActor
final class LivestreamJoinController<Factory: ViewFactory>: ObservableObject {
    @Published private(set) var livestreamState: LivestreamState
    @Published private(set) var countdown: TimeInterval

    let session: LivestreamSession
    private let joinPolicy: LivestreamPlayer<Factory>.JoinPolicy
    private let disposableBag = DisposableBag()
    private var countdownTask: AnyCancellable?

    /// A remote end should join a new call when backstage ends.
    private var shouldJoinFreshCall = false

    /// A local leave posts the same end notice as a remote end.
    /// That leave must not start another join.
    private var shouldIgnoreCallEnded = false

    init(
        session: LivestreamSession,
        joinPolicy: LivestreamPlayer<Factory>.JoinPolicy,
        livestreamState: LivestreamState,
        countdown: TimeInterval
    ) {
        self.session = session
        self.joinPolicy = joinPolicy
        self.livestreamState = livestreamState
        self.countdown = countdown
    }

    func joinOnAppear() {
        guard joinPolicy == .auto else { return }
        join()
    }

    func leaveOnDisappear() {
        guard joinPolicy == .auto else { return }
        leave(initiator: .app)
    }

    func handleCallEnded(_ notification: Notification) {
        guard joinPolicy == .auto else { return }
        guard let ended = notification.object as? Call else { return }
        guard ended.cId == session.call.cId else { return }
        guard !consumeIgnoredCallEnded() else { return }
        shouldJoinFreshCall = true
        livestreamState = .backstage
    }

    func handleBackstageChange() {
        if shouldJoinWhenBackstageEnds {
            replaceCallAndJoin()
            return
        }
        guard livestreamState != .joining else { return }
        applyCallState()
    }

    func join() {
        let call = session.call
        Task(disposableBag: disposableBag) { [weak self] in
            await self?.performJoin(call)
        }
    }

    func leave(initiator: Call.LeaveInitiator = .user) {
        shouldIgnoreCallEnded = true
        session.call.leave(initiator: initiator, reason: "leaveLivestream")
        disposableBag.removeAll()
        countdownTask = nil
        livestreamState = .initial
    }

    private var shouldJoinWhenBackstageEnds: Bool {
        shouldJoinFreshCall && joinPolicy == .auto && !session.call.state.backstage
    }

    private func consumeIgnoredCallEnded() -> Bool {
        guard shouldIgnoreCallEnded else { return false }
        shouldIgnoreCallEnded = false
        return true
    }

    private func replaceCallAndJoin() {
        shouldJoinFreshCall = false
        livestreamState = .joining
        let current = session.call
        let fresh = InjectedValues[\.streamVideo].call(
            callType: current.callType,
            callId: current.callId
        )
        guard fresh !== current else { return }
        session.call = fresh
        join()
    }

    private func performJoin(_ call: Call) async {
        do {
            livestreamState = .joining
            try await call.join(
                callSettings: CallSettings(audioOn: false, videoOn: false)
            )
            livestreamState = call.state.backstage ? .backstage : .live
        } catch {
            livestreamState = .error
            log.error("Error joining livestream")
        }
    }

    private func applyCallState() {
        livestreamState = LivestreamState(call: session.call)
        if
            let startsAt = session.call.state.startsAt,
            livestreamState == .backstage,
            countdownTask == nil {
            startCountdown(at: startsAt)
        } else if livestreamState == .live {
            stopCountdown()
        }
    }

    private func startCountdown(at startsAt: Date) {
        countdownTask = DefaultTimer
            .publish(every: 1)
            .receive(on: DispatchQueue.main)
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] _ in
                self?.updateCountdown(at: startsAt)
            }
    }

    private func updateCountdown(at startsAt: Date) {
        countdown = startsAt.timeIntervalSinceNow
        guard countdown <= 0 else { return }
        stopCountdown()
        countdown = 0
    }

    private func stopCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }
}
