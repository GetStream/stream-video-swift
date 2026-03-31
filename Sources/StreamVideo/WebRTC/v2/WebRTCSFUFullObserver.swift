//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Observes SFU full errors and exposes the received error payload.
final class WebRTCSFUFullObserver {

    /// The hostname for the SFU adapter being observed.
    let hostname: String
    /// The last `SFU_FULL` error received from the observed adapter.
    ///
    /// The value remains `nil` until an `SFU_FULL` event is observed.
    var shouldMigrateError: Stream_Video_Sfu_Event_Error? { shouldMigrateSubject.value }
    /// Publishes `SFU_FULL` error events from the observed adapter.
    ///
    /// The stream emits only non-`nil` values, preserving the full SFU error
    /// payload so downstream stages can honor the attached reconnect strategy.
    var publisher: AnyPublisher<Stream_Video_Sfu_Event_Error, Never> {
        shouldMigrateSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private let shouldMigrateSubject: CurrentValueSubject<
        Stream_Video_Sfu_Event_Error?,
        Never
    > = .init(nil)
    private var cancellable: AnyCancellable?

    /// Creates a new observer for SFU full errors on the provided adapter.
    /// - Parameter sfuAdapter: The SFU adapter whose error events are observed.
    init(_ sfuAdapter: SFUAdapter) {
        self.hostname = sfuAdapter.hostname
        cancellable = sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
            .filter { $0.error.code == .sfuFull }
            .sink { [weak self] in
                // The SFU has explicitly rejected this edge due to capacity;
                // mark migration as required for the current join flow.
                self?.shouldMigrateSubject.send($0)
            }
    }
}
