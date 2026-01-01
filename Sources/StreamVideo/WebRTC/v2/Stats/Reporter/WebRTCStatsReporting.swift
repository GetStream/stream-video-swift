//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Abstracts the stats reporting interface..
protocol WebRTCStatsReporting: AnyObject, Sendable {
    /// The reporting interval, in seconds.
    var interval: TimeInterval { get set }
    
    /// The SFU adapter used for delivery.
    var sfuAdapter: SFUAdapter? { get set }
    
    /// Manually triggers a stats delivery.
    func triggerDelivery()
}
