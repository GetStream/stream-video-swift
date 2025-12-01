//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension Logger {

    public enum WebRTC {
        public enum LogMode: Sendable { case none, validFilesOnly, all }

        public nonisolated(unsafe) static var mode: LogMode = .all {
            didSet { RTCLogger.default.didUpdate(mode: mode) }
        }

        nonisolated(unsafe) static var severity: RTCLoggingSeverity = .init(LogConfig.level) {
            didSet { RTCLogger.default.didUpdate(severity: severity) }
        }

        enum ValidFile: String {
            case audioEngineDevice = "audio_engine_device.mm"
        }

        nonisolated(unsafe) static var validFiles: [ValidFile] = [
            .audioEngineDevice
        ]
    }
}

extension RTCLoggingSeverity {

    init(_ logLevel: LogLevel) {
        switch logLevel {
        case .debug:
            self = .verbose
        case .info:
            self = .info
        case .warning:
            self = .warning
        case .error:
            self = .error
        }
    }
}

extension Logger.WebRTC {
    final class RTCLogger: @unchecked Sendable {
        static let `default` = RTCLogger()

        private let logger = RTCCallbackLogger()
        private var isRunning = false
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

        private init() {
            didUpdate(mode: mode)
        }

        func didUpdate(severity: RTCLoggingSeverity) {
            processingQueue.addOperation { [weak self] in
                self?.logger.severity = severity
            }
        }

        func didUpdate(mode: LogMode) {
            processingQueue.addOperation { [weak self] in
                guard let self else {
                    return
                }

                guard mode != .none else {
                    logger.stop()
                    isRunning = false
                    return
                }

                guard !self.isRunning else {
                    return
                }

                logger.start { [weak self] in self?.process($0) }

                self.isRunning = true
            }
        }

        private func process(_ message: String) {
            let trimmedMessage = message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            switch severity {
            case .none, .verbose:
                if isMessageFromValidFile(trimmedMessage) {
                    log.debug(trimmedMessage, subsystems: .webRTCInternal)
                }
            case .info:
                if isMessageFromValidFile(trimmedMessage) {
                    log.info(trimmedMessage, subsystems: .webRTCInternal)
                }
            case .warning:
                log.warning(trimmedMessage, subsystems: .webRTCInternal)
            case .error:
                log.error(trimmedMessage, subsystems: .webRTCInternal)
            @unknown default:
                log.debug(trimmedMessage, subsystems: .webRTCInternal)
            }
        }

        private func isMessageFromValidFile(_ message: String) -> Bool {
            guard mode == .validFilesOnly, !validFiles.isEmpty else {
                return true
            }

            for validFile in validFiles {
                if message.contains(validFile.rawValue) {
                    return true
                }
            }
            return false
        }
    }
}
