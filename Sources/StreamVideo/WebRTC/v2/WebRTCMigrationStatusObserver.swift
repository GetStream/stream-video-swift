//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// If we are migrating from another SFU, then we need to wait until a deadline (defaults to 7)
/// for **Stream_Video_Sfu_Event_ParticipantMigrationComplete** to arrive.
///
/// If the SFU doesn't send the event before the deadline expires we should consider that the migration failed
/// and try to rejoin.
final class WebRTCMigrationStatusObserver: @unchecked Sendable {

    enum State { case idle, running, failed(Error), completed }

    private let connectURL: URL
    private var task: Task<Void, Never>?
    private let disposableBag = DisposableBag()

    private let state = CurrentValueSubject<State, Never>(.running)

    init(
        migratingFrom sfuAdapter: SFUAdapter,
        deadline: TimeInterval = WebRTCConfiguration.timeout.migrationCompletion
    ) {
        connectURL = sfuAdapter.connectURL
        task = Task(disposableBag: disposableBag) { [weak self] in
            guard let self else {
                return
            }
            do {
                _ = try await sfuAdapter
                    .publisher(eventType: Stream_Video_Sfu_Event_ParticipantMigrationComplete.self)
                    .nextValue(timeout: deadline)
                try Task.checkCancellation()
                state.send(.completed)
            } catch is CancellationError {
                state.send(.failed(CancellationError()))
            } catch {
                state.send(.failed(
                    ClientError(
                        """
                        Migration from hostname:\(connectURL) failed after \(deadline)
                        where we didn't receive a ParticipantMigrationComplete
                        event.
                        """
                    )
                ))
            }
        }
    }

    deinit {
        task?.cancel()
    }

    /// Stops waiting when the owning migration stage has ended.
    func cancel() {
        task?.cancel()
    }

    func observeMigrationStatus() async throws {
        try Task.checkCancellation()
        // Subscribe to terminal states directly. Reading state and then
        // dropping the first value can miss completion between those steps.
        let migrationStatus = try await state
            .filter {
                if case .running = $0 { return false }
                return true
            }
            .nextValue()
        try Task.checkCancellation()

        switch migrationStatus {
        case let .failed(error):
            throw error
        case .completed:
            log.debug(
                "Migration from connectURL:\(connectURL) completed successfully!",
                subsystems: .webRTC
            )
        default:
            return
        }
    }
}
