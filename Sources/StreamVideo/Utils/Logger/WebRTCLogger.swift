//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog
import StreamWebRTC

final class WebRTCLogger: @unchecked Sendable {

    static let `default` = WebRTCLogger()

    var enabled: Bool = false {
        didSet { didUpdate(enabled) }
    }

    var severity: RTCLoggingSeverity = .error {
        didSet { webRTCLogger.severity = severity }
    }

    private let webRTCLogger: RTCCallbackLogger = .init()

    private init() {
        webRTCLogger.severity = .verbose
    }

    private func didUpdate(_ enabled: Bool) {
        guard enabled else {
            webRTCLogger.stop()
            return
        }
        webRTCLogger.start { message, severity in
            let trimmedMessage = message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            switch severity {
            case .none, .verbose:
                log.debug(trimmedMessage, subsystems: .webRTCInternal)
            case .info:
                log.info(trimmedMessage, subsystems: .webRTCInternal)
            case .warning:
                log.warning(trimmedMessage, subsystems: .webRTCInternal)
            case .error:
                log.error(trimmedMessage, subsystems: .webRTCInternal)
            @unknown default:
                log.debug(trimmedMessage, subsystems: .webRTCInternal)
            }
        }
    }
}
