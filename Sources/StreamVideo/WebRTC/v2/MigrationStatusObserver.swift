//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// If we are migrating from another SFU, then we need to wait until a deadline (defaults to 7)
/// for **Stream_Video_Sfu_Event_ParticipantMigrationComplete** to arrive.
///
/// If the SFU doesn't send the event before the deadline expires we should consider that the migration failed
/// and try to rejoin.
final class MigrationStatusObserver: @unchecked Sendable {

    enum State { case idle, running, failed(Error), completed }

    private let connectURL: URL
    private var task: Task<Void, Never>?

    @Published private var state: State = .running

    init(
        migratingFrom sfuAdapter: SFUAdapter,
        deadline: TimeInterval = 7
    ) {
        connectURL = sfuAdapter.connectURL
        task = Task {
            do {
                _ = try await sfuAdapter
                    .publisher(eventType: Stream_Video_Sfu_Event_ParticipantMigrationComplete.self)
                    .nextValue(timeout: deadline)
                state = .completed
            } catch {
                state = .failed(
                    ClientError(
                        """
                        Migration from hostname:\(connectURL) failed after \(deadline)
                        where we didn't receive a ParticipantMigrationComplete
                        event.
                        """
                    )
                )
            }
        }
    }

    deinit {
        task?.cancel()
    }

    func observeMigrationStatus() async throws {
        switch state {
        case .idle:
            return
        case .running:
            let migrationStatus = try await $state.nextValue(dropFirst: 1)
            switch migrationStatus {
            case let .failed(error):
                throw error
            case .completed:
                log.debug(
                    """
                    Migration from connectURL:\(connectURL) completed successfully!
                    """,
                    subsystems: .webRTC
                )
            default:
                return
            }
        case let .failed(error):
            throw error
        case .completed:
            return
        }
    }
}
