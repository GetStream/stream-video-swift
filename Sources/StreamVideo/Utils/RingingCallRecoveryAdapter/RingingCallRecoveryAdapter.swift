//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Reloads the ringing call from the coordinator after the WebSocket
/// reconnects.
///
/// Accept, reject, and end for an outgoing ring arrive as coordinator
/// events. If the socket drops while we are still ringing, those events
/// never reach this device and `Call.state` stays stale — the caller
/// never joins.
///
/// On every `WSConnected` this adapter calls `get()` on
/// `state.ringingCall` without `ring: true`, so session fields such as
/// `acceptedBy` are current again without paging callees a second time.
/// SwiftUI then turns that session into the same events it already
/// handles from the socket.
final class RingingCallRecoveryAdapter: @unchecked Sendable {

    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private weak var streamVideo: StreamVideo?

    init(_ streamVideo: StreamVideo) {
        self.streamVideo = streamVideo

        streamVideo
            .rawEventPublisher
            .compactMap {
                switch $0 {
                case let .internalEvent(event):
                    return event
                default:
                    return nil
                }
            }
            .filter { $0 is WSConnected }
            .receive(on: processingQueue)
            .sinkTask(storeIn: disposableBag) { [weak self] _ in
                await self?.didConnect()
            }
            .store(in: disposableBag)
    }

    private func didConnect() async {
        guard
            let ringingCall = await MainActor.run(body: {
                streamVideo?.state.ringingCall
            })
        else {
            return
        }

        do {
            _ = try await ringingCall.get()
        } catch {
            log.error(error)
        }
    }
}
