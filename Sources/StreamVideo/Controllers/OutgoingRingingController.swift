//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Observes an outgoing ringing call and ends it when the app moves to
/// the background.
///
/// The controller is active only while
/// `StreamVideo.State.ringingCall` matches the provided call CID.
/// When ringing stops or another call becomes the ringing call, the
/// application state observation is cancelled.
final class OutgoingRingingController: @unchecked Sendable {
    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    private let callCiD: String
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private let handler: () async throws -> Void
    private var ringingCallCancellable: AnyCancellable?
    private var appStateCancellable: AnyCancellable?
    private let disposableBag = DisposableBag()

    /// Creates a controller for the outgoing ringing call identified by
    /// the provided call CID.
    ///
    /// - Parameters:
    ///   - streamVideo: The active `StreamVideo` instance.
    ///   - callCiD: The call CID to observe in `ringingCall`.
    ///   - handler: The async operation that ends the ringing call.
    init(
        streamVideo: StreamVideo,
        callCiD: String,
        handler: @escaping () async throws -> Void
    ) {
        self.callCiD = callCiD
        self.handler = handler
        ringingCallCancellable = streamVideo
            .state
            .$ringingCall
            .receive(on: processingQueue)
            .sink { [weak self] in self?.didUpdateRingingCall($0) }
    }

    // MARK: - Private Helpers

    private func didUpdateRingingCall(_ call: Call?) {
        guard call?.cId == callCiD else {
            deactivate()
            return
        }
        activate()
    }

    private func activate() {
        appStateCancellable = applicationStateAdapter
            .statePublisher
            /// We ignore .unknown on purpose to cover cases like, starting a call from the Recents app where
            /// entering the ringing flow may happen before the AppState has been stabilised
            .filter { $0 == .background }
            .log(.info) { [callCiD] _ in "Ringing call end requested. cid=\(callCiD) reason=background" }
            .receive(on: processingQueue)
            .sinkTask(storeIn: disposableBag) { [weak self] _ in await self?.endCall() }
    }

    private func deactivate() {
        appStateCancellable?.cancel()
        appStateCancellable = nil
    }

    private func endCall() async {
        do {
            try await handler()
        } catch {
            log.error("Ringing call end failed. cid=\(callCiD) reason=background", error: error)
        }
        deactivate()
    }
}
