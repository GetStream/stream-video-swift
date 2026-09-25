//
//  RTCStatisticsReport+Dummy.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 25/9/26.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

extension RTCStatisticsReport {

    static func dummy(
        factory: PeerConnectionFactory = PeerConnectionFactory.mock(),
        configuration: RTCConfiguration = .init(),
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCStatisticsReport {
        let peerConnection = try factory.makePeerConnection(
            configuration: configuration,
            constraints: constraints,
            delegate: nil
        )

        defer { peerConnection.close() }

        return await withCheckedContinuation {
            continuation in
            peerConnection.statistics {
                continuation.resume(returning: $0)
            }
        }
    }
}
