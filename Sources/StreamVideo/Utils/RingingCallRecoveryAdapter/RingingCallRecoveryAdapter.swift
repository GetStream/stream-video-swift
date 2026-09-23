//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Recovers missed ringing events and owns the caller's ringing deadline.
/// Incoming calls refresh on reconnect; only the caller polls ring state.
final class RingingCallRecoveryAdapter: @unchecked Sendable {

    enum Mode { case ringingCall, activeCall }

    private weak var call: Call?
    private weak var streamVideo: StreamVideo?
    private let disposableBag = DisposableBag()
    private let quietPeriod: TimeInterval
    private let pollInterval: TimeInterval
    private let finalReadGrace: TimeInterval
    // Invalidate synchronously, before queued main-actor work can run.
    @Atomic private var generation: UInt64 = 0

    @MainActor private var mode: Mode?
    @MainActor private var startedAt: TimeInterval = 0
    @MainActor private var sessionId: String?
    @MainActor private var membersIds: Set<String> = []
    @MainActor private var quietUntil: TimeInterval = 0
    @MainActor private var recoveryTask: Task<Void, Never>?

    init(
        _ call: Call,
        quietPeriod: TimeInterval = 15,
        pollInterval: TimeInterval = 5,
        finalReadGrace: TimeInterval = 7
    ) {
        self.call = call
        self.quietPeriod = quietPeriod
        self.pollInterval = pollInterval
        self.finalReadGrace = finalReadGrace
    }

    func configure(on streamVideo: StreamVideo) {
        guard self.streamVideo !== streamVideo else { return }
        self.streamVideo = streamVideo
        Task { @MainActor [weak self, weak streamVideo] in
            guard let self, let streamVideo else { return }
            observe(streamVideo)
        }
    }

    @MainActor
    private func observe(_ streamVideo: StreamVideo) {
        call?.state.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.startIfReady() }
            }
            .store(in: disposableBag)

        streamVideo.eventPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                Task { @MainActor [weak self] in self?.didReceive(event) }
            }
            .store(in: disposableBag)

        streamVideo.rawEventPublisher
            .receive(on: DispatchQueue.main)
            .compactMap {
                if case let .internalEvent(event) = $0 { return event }
                return nil
            }
            .filter { $0 is WSConnected }
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in await self?.didConnect() }
            }
            .store(in: disposableBag)
    }

    func activate(mode: Mode = .ringingCall, membersIds: [String]? = nil) {
        _generation.mutate { $0 &+= 1 }
        let currentGeneration = generation
        Task { @MainActor [weak self] in
            guard let self, self.generation == currentGeneration else { return }
            recoveryTask?.cancel()
            recoveryTask = nil
            self.mode = mode
            self.membersIds = Set(membersIds ?? [])
            startedAt = ProcessInfo.processInfo.systemUptime
            sessionId = nil
            startIfReady()
        }
    }

    func stop() {
        _generation.mutate { $0 &+= 1 }
        let currentGeneration = generation
        Task { @MainActor [weak self] in
            guard let self, self.generation == currentGeneration else { return }
            recoveryTask?.cancel()
            recoveryTask = nil
            mode = nil
            sessionId = nil
        }
    }

    @MainActor
    private func startIfReady() {
        guard let call, let streamVideo, let mode,
              call.state.createdBy?.id == streamVideo.user.id,
              isCurrentCall(mode: mode) else { return }
        let newSessionId = call.state.session?.id
        guard recoveryTask == nil || sessionId != newSessionId else { return }
        // Hydration keeps the original deadline; a new session starts a ring.
        if let sessionId, let newSessionId, sessionId != newSessionId {
            startedAt = ProcessInfo.processInfo.systemUptime
        }
        recoveryTask?.cancel()
        sessionId = newSessionId
        quietUntil = startedAt + quietPeriod
        let currentGeneration = generation
        let timeoutMs = call.state.settings?.ring.autoCancelTimeoutMs ?? 30000
        let deadline = startedAt + Double(timeoutMs) / 1000
        recoveryTask = Task { @MainActor [weak self] in
            await self?.recover(sessionId: newSessionId, generation: currentGeneration, deadline: deadline)
        }
    }

    @MainActor
    private func isCurrentCall(mode: Mode) -> Bool {
        guard let call, let streamVideo else { return false }
        switch mode {
        case .ringingCall: return streamVideo.state.ringingCall === call
        case .activeCall: return streamVideo.state.activeCall === call
        }
    }

    @MainActor
    private func isCurrent(sessionId: String?, generation: UInt64) -> Bool {
        guard !Task.isCancelled,
              self.generation == generation,
              let mode,
              isCurrentCall(mode: mode),
              call?.state.session?.id == sessionId else { return false }
        return true
    }

    @MainActor
    private func hasOutcome() -> Bool {
        guard let call, let streamVideo else { return true }
        if call.state.endedAt != nil { return true }
        guard let session = call.state.session else { return false }
        if session.endedAt != nil { return true }
        let recipients = membersIds.isEmpty
            ? Set(call.state.members.map(\.id))
            : membersIds
        return session.acceptedBy.keys.contains {
            $0 != streamVideo.user.id && (recipients.isEmpty || recipients.contains($0))
        }
    }

    @MainActor
    private func recover(sessionId: String?, generation: UInt64, deadline: TimeInterval) async {
        var nextRead = quietUntil
        var canRead = sessionId != nil
        while isCurrent(sessionId: sessionId, generation: generation) && !hasOutcome() {
            let now = ProcessInfo.processInfo.systemUptime
            let readAt = canRead ? min(max(nextRead, quietUntil), deadline) : deadline
            if readAt > now {
                do { try await sleep(until: readAt) }
                catch { return }
                continue
            }
            guard canRead, let sessionId else { break }

            // Reads are sequential. A read crossing the deadline is the final
            // read, bounded by grace even if the HTTP transport ignores cancel.
            let result = await withFirstTaskCompleted(
                { [weak self] in
                    try await self?.read(sessionId: sessionId, generation: generation)
                },
                { [finalReadGrace] in
                    try await self.sleep(until: deadline + finalReadGrace)
                }
            )
            switch result {
            case let .first(.failure(error)):
                if let error = error as? APIError,
                   error.statusCode == 400 || error.statusCode == 404 {
                    canRead = false
                } else {
                    log.error(error)
                }
            case .first(.success): break
            case .second: break
            case .cancelled: return
            }
            if ProcessInfo.processInfo.systemUptime >= deadline { break }
            nextRead = ProcessInfo.processInfo.systemUptime + pollInterval
        }
        await finish(sessionId: sessionId, generation: generation)
    }

    private func sleep(until deadline: TimeInterval) async throws {
        let remaining = max(0, deadline - ProcessInfo.processInfo.systemUptime)
        try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
    }

    @MainActor
    private func read(sessionId: String, generation: UInt64) async throws {
        guard isCurrent(sessionId: sessionId, generation: generation),
              let call else { return }
        let response = try await call.coordinatorClient.getCallRingState(
            type: call.callType,
            id: call.callId,
            callSessionId: sessionId
        )
        // A cancelled HTTP request can still complete for a replaced ring.
        guard isCurrent(sessionId: sessionId, generation: generation),
              response.callCid == call.cId,
              response.sessionId == sessionId else { return }
        _ = call.state.update(from: response)
    }

    @MainActor
    private func finish(sessionId: String?, generation: UInt64) async {
        guard isCurrent(sessionId: sessionId, generation: generation),
              !hasOutcome(), let call, let streamVideo else { return }
        let reason = await streamVideo.rejectionReasonProvider.reason(
            for: call.cId,
            ringTimeout: true
        )
        guard isCurrent(sessionId: sessionId, generation: generation),
              !hasOutcome() else { return }
        // Local teardown must not wait for rejection HTTP or cancel that request.
        Task {
            do {
                _ = try await call.coordinatorClient.rejectCall(
                    type: call.callType,
                    id: call.callId,
                    rejectCallRequest: .init(reason: reason)
                )
            } catch { log.error(error) }
        }
        call.leave(reason: "timeout")
    }

    @MainActor
    private func didReceive(_ event: VideoEvent) {
        guard let call, let sessionId else { return }
        let matches: Bool
        switch event {
        case let .typeCallAcceptedEvent(value):
            matches = value.callCid == call.cId && value.call.session?.id == sessionId
        case let .typeCallRejectedEvent(value):
            matches = value.callCid == call.cId && value.call.session?.id == sessionId
        case let .typeCallMissedEvent(value):
            matches = value.callCid == call.cId && value.sessionId == sessionId
        default:
            matches = false
        }
        if matches { quietUntil = ProcessInfo.processInfo.systemUptime + quietPeriod }
    }

    @MainActor
    private func didConnect() async {
        guard let call, let streamVideo,
              streamVideo.state.ringingCall === call else { return }
        do { _ = try await call.get() }
        catch { log.error(error) }
    }
}
