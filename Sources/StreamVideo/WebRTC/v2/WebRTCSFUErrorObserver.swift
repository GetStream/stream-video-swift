//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Observes terminal SFU errors used by joining and migration flows.
final class WebRTCSFUErrorObserver {

    /// The hostname for the SFU adapter being observed.
    let hostname: String

    /// The last `SFU_FULL` error received from the observed adapter.
    ///
    /// The value remains `nil` until an `SFU_FULL` event is observed.
    var shouldMigrateError: Stream_Video_Sfu_Event_Error? {
        guard errorSubject.value?.error.code == .sfuFull else { return nil }
        return errorSubject.value
    }

    /// Publishes `SFU_FULL` error events from the observed adapter.
    ///
    /// The stream emits only non-`nil` values, preserving the full SFU error
    /// payload so downstream stages can honor the attached reconnect strategy.
    var publisher: AnyPublisher<Stream_Video_Sfu_Event_Error, Never> {
        errorSubject
            .compactMap { $0 }
            .filter { $0.error.code == .sfuFull }
            .eraseToAnyPublisher()
    }

    /// Publishes terminal errors that can reject an in-flight join.
    var joiningPublisher: AnyPublisher<Stream_Video_Sfu_Event_Error, Never> {
        errorSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private let errorSubject: CurrentValueSubject<
        Stream_Video_Sfu_Event_Error?,
        Never
    > = .init(nil)
    private var cancellable: AnyCancellable?

    /// Creates an observer for terminal SFU errors on the provided adapter.
    /// - Parameter sfuAdapter: The SFU adapter whose error events are observed.
    init(_ sfuAdapter: SFUAdapter) {
        self.hostname = sfuAdapter.hostname
        cancellable = sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
            .filter {
                switch $0.error.code {
                case .sfuFull, .sfuShuttingDown, .callParticipantLimitReached:
                    return true
                default:
                    return false
                }
            }
            .sink { [weak self] in
                self?.errorSubject.send($0)
            }
    }
}
