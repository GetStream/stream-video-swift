//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamVideoSwiftUI

/// Demo interceptor that waits until another participant announces readiness
/// through a custom event before the local join flow finishes.
final class DemoCallJoinInterceptor: CallJoinIntercepting, @unchecked Sendable {
    @Injected(\.streamVideo) private var streamVideo

    private var ringingCallCancellable: AnyCancellable?
    private var customEventCancellable: AnyCancellable?
    private let customEventKey: String
    private var currentUserID: String = ""

    private let hasOtherReadyParticipants: CurrentValueSubject<Bool, Never> = .init(false)

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
                .sink { [weak self] in self?.didUpdate(ringingCall: $0) }
        }
    }

    // MARK: - CallJoinIntercepting

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
            .filter { $0 }
            .nextValue()
    }

    // MARK: - Private Helpers

    private func didUpdate(ringingCall: Call?) {
        cancelCustomEventObservation()

        guard let ringingCall else {
            return
        }

        customEventCancellable = ringingCall
            .eventPublisher(for: CustomVideoEvent.self)
            .compactMap { [customEventKey] in $0.custom[customEventKey]?.stringValue }
            .filter { [currentUserID] in $0 != currentUserID }
            .log(.debug) { "Call presence event was received for userID:\($0)" }
            .map { _ in true }
            .sink { [weak self] in self?.hasOtherReadyParticipants.send($0) }
        
        log.debug("Call presence events observation has started.")
    }

    private func cancelCustomEventObservation() {
        guard customEventCancellable != nil else {
            return
        }
        customEventCancellable?.cancel()
        customEventCancellable = nil
        hasOtherReadyParticipants.send(false)
        log.debug("Call presence events observation was cancelled.")
    }
}
