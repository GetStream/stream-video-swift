//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

protocol WebRTCStatsAdapting: AnyObject, Sendable {
    var sfuAdapter: SFUAdapter? { get set }

    var publisher: RTCPeerConnectionCoordinator? { get set }

    var subscriber: RTCPeerConnectionCoordinator? { get set }

    var callSettings: CallSettings? { get set }

    var audioSession: StreamAudioSession? { get set }

    var deliveryInterval: TimeInterval { get set }

    var isTracingEnabled: Bool { get set }

    var reconnectAttempts: UInt32 { get set }

    var latestReportPublisher: AnyPublisher<CallStatsReport, Never> { get }

    var sessionID: String { get }

    var unifiedSessionID: String { get }

    func scheduleStatsReporting()

    func trace(_ trace: WebRTCTrace)
}
