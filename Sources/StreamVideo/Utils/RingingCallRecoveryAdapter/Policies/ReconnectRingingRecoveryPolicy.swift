//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Reloads ring state with `get()` after a WebSocket reconnect.
/// - Caller: refreshes outgoing rings even without polling or a local session.
/// - Callee: refreshes incoming rings without ringing again.
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
