//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
import StreamWebRTC

extension LogConfig {
    /// Toggles internal WebRTC logging on or off.
    public static var webRTCLogsEnabled: Bool {
        get { Logger.WebRTC.mode != .none }
        set { Logger.WebRTC.mode = newValue ? .all : .none }
    }
}

extension Logger {

    public enum WebRTC {
        public enum LogMode: Sendable { case none, validFilesOnly, all }

        public nonisolated(unsafe) static var mode: LogMode = .all {
            didSet { RTCLogger.default.didUpdate(mode: mode) }
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
        @unknown default:
            self = .verbose
        }
    }
}

extension Logger.WebRTC {
    final class RTCLogger: @unchecked Sendable {
        static let `default` = RTCLogger()

        private let logger = RTCCallbackLogger()
        private var isRunning = false
        private var currentMode: LogMode = .none
        private var currentSeverity = RTCLoggingSeverity(LogConfig.level)
        private let processingQueue = DispatchQueue(label: "io.getstream.webrtc.logger")
        private var levelCancellable: AnyCancellable?

        private init() {
            levelCancellable = LogConfig.levelPublisher
                .sink { [weak self] in self?.didUpdate(severity: .init($0)) }
            didUpdate(mode: mode)
        }

        func didUpdate(severity: RTCLoggingSeverity) {
            processingQueue.async { [weak self] in
                guard let self, currentSeverity != severity else {
                    return
                }
                currentSeverity = severity
                restartLogging()
            }
        }

        func didUpdate(mode: LogMode) {
            processingQueue.async { [weak self] in
                guard let self else {
                    return
                }

                guard currentMode != mode else {
                    return
                }
                currentMode = mode
                restartLogging()
            }
        }

        private func restartLogging() {
            if isRunning {
                logger.stop()
                isRunning = false
            }
            guard currentMode != .none else { return }

            logger.severity = currentSeverity
            let mode = currentMode
            let files = validFiles
            logger.start(messageAndSeverityHandler: { [weak self] in
                self?.process($0, severity: $1, mode: mode, validFiles: files)
            })
            isRunning = true
        }

        private func process(
            _ message: String,
            severity: RTCLoggingSeverity,
            mode: LogMode,
            validFiles: [ValidFile]
        ) {
            let trimmedMessage = message.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if mode == .validFilesOnly,
               !validFiles.isEmpty,
               severity == .verbose || severity == .info,
               !validFiles.contains(where: { trimmedMessage.contains($0.rawValue) }) {
                return
            }

            switch severity {
            case .none:
                return
            case .verbose:
                log.debug(trimmedMessage, subsystems: .webRTC)
            case .info:
                log.info(trimmedMessage, subsystems: .webRTC)
            case .warning:
                log.warning(trimmedMessage, subsystems: .webRTC)
            case .error:
                log.error(trimmedMessage, subsystems: .webRTC)
            @unknown default:
                log.debug(trimmedMessage, subsystems: .webRTC)
            }
        }
    }
}
