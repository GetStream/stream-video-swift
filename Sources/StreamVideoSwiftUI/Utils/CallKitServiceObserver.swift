//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

/// Replays the latest CallKit lifecycle event to `CallViewModel`.
///
/// `CallKitService` can emit events before SwiftUI has rebuilt the view model
/// after the app is launched from CallKit. Caching the latest value lets the
/// view model recover the intended transitional UI state immediately.
final class CallKitServiceObserver {
    @Injected(\.callKitService) private var callKitService

    /// Publishes the latest CallKit event so `CallViewModel` can react to
    /// asynchronous system actions.
    var publisher: AnyPublisher<CallKitService.Event, Never> { subject.eraseToAnyPublisher() }

    /// Returns the latest bridged CallKit event for synchronous state
    /// reconciliation paths such as `setActiveCall`.
    var value: CallKitService.Event { subject.value }

    /// Replays the most recent CallKit event to new subscribers.
    private let subject: CurrentValueSubject<CallKitService.Event, Never> = .init(.idle)

    /// Serializes CallKit event delivery before we cache and replay it locally.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private var cancellable: AnyCancellable?

    init() {
        cancellable = callKitService
            .eventPipeline
            .receive(on: processingQueue)
            .log(.debug) { "CallKitService observer received:\($0)" }
            // Cache the latest system event so new subscriptions can recover
            // the current transitional CallKit state immediately.
            .sink { [weak self] in self?.subject.send($0) }
    }
}
