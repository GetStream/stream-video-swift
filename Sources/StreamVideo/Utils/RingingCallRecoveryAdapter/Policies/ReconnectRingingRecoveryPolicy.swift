//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Refreshes the ringing call every time the WebSocket reconnects.
///
/// Events sent while the socket was down are lost, so the action reloads
/// the call with `get()`. It does not pass `ring: true`, so callees are
/// not paged a second time.
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
