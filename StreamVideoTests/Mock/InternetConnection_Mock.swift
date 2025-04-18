//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

/// Mock implementation of `InternetConnectionMonitor`
final class InternetConnectionMonitor_Mock: InternetConnectionMonitor {
    weak var delegate: InternetConnectionDelegate?

    var status: InternetConnectionStatus = .unknown {
        didSet {
            delegate?.internetConnectionStatusDidChange(status: status)
        }
    }

    var isStarted = false

    func start() {
        isStarted = true
        status = .available(.great)
    }

    func stop() {
        isStarted = false
        status = .unknown
    }
}
