//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Refreshes an incoming or outgoing ring when the WebSocket reconnects.
///
/// Flow coverage:
/// - Caller: refreshes the outgoing ring after reconnecting.
/// - Callee: refreshes the incoming ring after reconnecting.
///
/// Reloads the full call with `get()` to recover events lost while offline.
/// It works when polling is disabled or the local session is unavailable.
/// It does not pass `ring: true`, so callees are not paged a second time.
///
/// Unlike polling, this policy needs a connection event. It cannot recover
/// a dropped ring outcome while the socket still appears connected.
final class ReconnectRingingRecoveryPolicy: RingingRecoveryPolicy {

    let actionPublisher: AnyPublisher<RingingRecoveryAction, Never>

    init(_ streamVideo: StreamVideo) {
        actionPublisher = streamVideo
            .rawEventPublisher
            .filter {
                guard case let .internalEvent(event) = $0 else {
                    return false
                }
                return event is WSConnected
            }
            .map { [weak streamVideo] _ -> RingingRecoveryAction in
                { [weak streamVideo] in
                    guard
                        let ringingCall = await MainActor.run(body: {
                            streamVideo?.state.ringingCall
                        })
                    else {
                        return
                    }
                    _ = try await ringingCall.get()
                }
            }
            .eraseToAnyPublisher()
    }
}
