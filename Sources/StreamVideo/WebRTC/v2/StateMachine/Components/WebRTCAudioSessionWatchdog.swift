//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Adapts `RTCAudioStore` state into a single audio-session readiness signal.
///
/// Readiness becomes `true` only after:
/// - the audio session has become active, and
/// - the current audio route is non-empty.
final class WebRTCAudioSessionWatchdog {
    @Injected(\.audioStore) private var audioStore

    /// Current readiness snapshot.
    var isReady: Bool { subject.value }
    /// Emits readiness updates and suppresses duplicates.
    var publisher: AnyPublisher<Bool, Never> { subject.removeDuplicates().eraseToAnyPublisher() }

    private let subject: CurrentValueSubject<Bool, Never> = .init(false)
    private let disposableBag = DisposableBag()

    init() {
        let isActivePublisher = audioStore
            .publisher(\.isActive)
            .removeDuplicates()
            .eraseToAnyPublisher()

        let currentRoutePublisher = audioStore
            .publisher(\.currentRoute)
            .map { $0 != .empty }
            .removeDuplicates()
            .eraseToAnyPublisher()

        Publishers
            .CombineLatest(isActivePublisher, currentRoutePublisher)
            .map { $0.0 && $0.1 }
            .sink { [weak self] in self?.subject.send($0) }
            .store(in: disposableBag)
    }
}

extension WebRTCTrace {
    /// Creates an audio-session readiness trace event.
    ///
    /// - Parameters:
    ///   - source: The readiness adapter providing current readiness state.
    ///   - timeout: Whether the trace is emitted due to watchdog timeout.
    init(_ source: WebRTCAudioSessionWatchdog, timeout: Bool = false) {
        self.init(
            id: nil,
            tag: "audio.session.\(source.isReady ? "ready" : timeout ? "timeout" : "preparing")",
            data: nil
        )
    }
}
