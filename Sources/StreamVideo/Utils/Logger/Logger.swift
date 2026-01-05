//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public var log: Logger {
    LogConfig.logger
}

/// Entity for identifying which subsystem the log message comes from.
public struct LogSubsystem: OptionSet, CustomStringConvertible, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let allCases: [LogSubsystem] = [
        .database,
        .httpRequests,
        .webSocket,
        .webRTC,
        .other,
        .offlineSupport,
        .peerConnectionPublisher,
        .peerConnectionSubscriber,
        .sfu,
        .iceAdapter,
        .mediaAdapter,
        .thermalState,
        .audioSession,
        .videoCapturer,
        .pictureInPicture,
        .callKit,
        .webRTCInternal,
        .audioRecording
    ]

    /// All subsystems within the SDK.
    public static let all: LogSubsystem = [
        .database,
        .httpRequests,
        .webSocket,
        .webRTC,
        .other,
        .offlineSupport,
        .peerConnectionPublisher,
        .peerConnectionSubscriber,
        .sfu,
        .iceAdapter,
        .mediaAdapter,
        .thermalState,
        .audioSession,
        .videoCapturer,
        .pictureInPicture,
        .callKit,
        .webRTCInternal,
        .audioRecording
    ]
    
    /// The subsystem responsible for any other part of the SDK.
    /// This is the default subsystem value for logging, to be used when `subsystem` is not specified.
    public static let other = Self(rawValue: 1 << 0)
    
    /// The subsystem responsible for database operations.
    public static let database = Self(rawValue: 1 << 1)
    /// The subsystem responsible for HTTP operations.
    public static let httpRequests = Self(rawValue: 1 << 2)
    /// The subsystem responsible for websocket operations.
    public static let webSocket = Self(rawValue: 1 << 3)
    /// The subsystem responsible for offline support.
    public static let offlineSupport = Self(rawValue: 1 << 4)
    /// The subsystem responsible for WebRTC.
    public static let webRTC = Self(rawValue: 1 << 5)
    /// The subsystem responsible for PeerConnections.
    public static let peerConnectionPublisher = Self(rawValue: 1 << 6)
    public static let peerConnectionSubscriber = Self(rawValue: 1 << 7)
    /// The subsystem responsible for SFU interaction.
    public static let sfu = Self(rawValue: 1 << 8)
    /// The subsystem responsible for ICE interactions.
    public static let iceAdapter = Self(rawValue: 1 << 9)
    /// The subsystem responsible for Media publishing/subscribing.
    public static let mediaAdapter = Self(rawValue: 1 << 10)
    /// The subsystem responsible for ThermalState observation.
    public static let thermalState = Self(rawValue: 1 << 11)
    /// The subsystem responsible for interacting with the AudioSession.
    public static let audioSession = Self(rawValue: 1 << 12)
    /// The subsystem responsible for VideoCapturing components.
    public static let videoCapturer = Self(rawValue: 1 << 13)
    /// The subsystem responsible for PicutreInPicture.
    public static let pictureInPicture = Self(rawValue: 1 << 14)
    /// The subsystem responsible for PicutreInPicture.
    public static let callKit = Self(rawValue: 1 << 15)
    public static let webRTCInternal = Self(rawValue: 1 << 16)
    public static let audioRecording = Self(rawValue: 1 << 17)

    public var description: String {
        switch rawValue {
        case LogSubsystem.other.rawValue:
            return "other"
        case LogSubsystem.database.rawValue:
            return "database"
        case LogSubsystem.httpRequests.rawValue:
            return "httpRequests"
        case LogSubsystem.webSocket.rawValue:
            return "webSocket"
        case LogSubsystem.offlineSupport.rawValue:
            return "offlineSupport"
        case LogSubsystem.webRTC.rawValue:
            return "webRTC"
        case LogSubsystem.peerConnectionPublisher.rawValue:
            return "peerConnection-publisher"
        case LogSubsystem.peerConnectionSubscriber.rawValue:
            return "peerConnection-subscriber"
        case LogSubsystem.sfu.rawValue:
            return "sfu"
        case LogSubsystem.iceAdapter.rawValue:
            return "iceAdapter"
        case LogSubsystem.mediaAdapter.rawValue:
            return "mediaAdapter"
        case LogSubsystem.thermalState.rawValue:
            return "thermalState"
        case LogSubsystem.audioSession.rawValue:
            return "audioSession"
        case LogSubsystem.videoCapturer.rawValue:
            return "videoCapturer"
        case LogSubsystem.pictureInPicture.rawValue:
            return "picture-in-picture"
        case LogSubsystem.callKit.rawValue:
            return "CallKit"
        case LogSubsystem.webRTCInternal.rawValue:
            return "webRTC-Internal"
        case LogSubsystem.audioRecording.rawValue:
            return "audioRecording"
        default:
            return "unknown(rawValue:\(rawValue)"
        }
    }
}

public enum LogConfig {
    /// Identifier for the logger. Defaults to empty.
    public nonisolated(unsafe) static var identifier = "" {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Output level for the logger.
    public nonisolated(unsafe) static var level: LogLevel = .error {
        didSet {
            invalidateLogger()
            Logger.WebRTC.severity = .init(level)
        }
    }
    
    /// Date formatter for the logger. Defaults to ISO8601
    public nonisolated(unsafe) static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }() {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Log formatters to be applied in order before logs are outputted. Defaults to empty (no formatters).
    /// Please see `LogFormatter` for more info.
    public nonisolated(unsafe) static var formatters = [LogFormatter]() {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing date in logs
    public nonisolated(unsafe) static var showDate = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing log level in logs
    public nonisolated(unsafe) static var showLevel = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing identifier in logs
    public nonisolated(unsafe) static var showIdentifier = false {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing thread name in logs
    public nonisolated(unsafe) static var showThreadName = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing file name in logs
    public nonisolated(unsafe) static var showFileName = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing line number in logs
    public nonisolated(unsafe) static var showLineNumber = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Toggle for showing function name in logs
    public nonisolated(unsafe) static var showFunctionName = true {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Subsystems for the logger
    public nonisolated(unsafe) static var subsystems: LogSubsystem = .all {
        didSet {
            invalidateLogger()
        }
    }
    
    /// Destination types this logger will use.
    ///
    /// Logger will initialize the destinations with its own parameters. If you want full control on the parameters, use `destinations` directly,
    /// where you can pass parameters to destination initializers yourself.
    public nonisolated(unsafe) static var destinationTypes: [LogDestination.Type] = [ConsoleLogDestination.self] {
        didSet {
            invalidateLogger()
        }
    }
    
    private static let _destinations: AtomicStorage<[LogDestination]?> = .init(nil)

    /// Destinations for the default logger. Please see `LogDestination`.
    /// Defaults to only `ConsoleLogDestination`, which only prints the messages.
    ///
    /// - Important: Other options in `ChatClientConfig.Logging` will not take affect if this is changed.
    public static var destinations: [LogDestination] {
        get {
            if let destinations = _destinations.get() {
                return destinations
            } else {
                let _destinationTypes = destinationTypes
                let newDestinations = _destinationTypes.map {
                    $0.init(
                        identifier: identifier,
                        level: level,
                        subsystems: subsystems,
                        showDate: showDate,
                        dateFormatter: dateFormatter,
                        formatters: formatters,
                        showLevel: showLevel,
                        showIdentifier: showIdentifier,
                        showThreadName: showThreadName,
                        showFileName: showFileName,
                        showLineNumber: showLineNumber,
                        showFunctionName: showFunctionName
                    )
                }
                _destinations.set(newDestinations)
                return newDestinations
            }
        }
        set {
            invalidateLogger()
            _destinations.set(newValue)
        }
    }
    
    /// Underlying logger instance to control singleton.
    private nonisolated(unsafe) static var _logger: Logger?

    /// Logger instance to be used by StreamChat.
    ///
    /// - Important: Other options in `LogConfig` will not take affect if this is changed.
    public static var logger: Logger {
        get {
            if let logger = _logger {
                return logger
            } else {
                _logger = Logger(identifier: identifier, destinations: destinations)
                return _logger!
            }
        }
        set {
            _logger = newValue
        }
    }

    public static var webRTCLogsEnabled: Bool {
        get { Logger.WebRTC.mode != .none }
        set { Logger.WebRTC.mode = newValue ? .all : .none }
    }

    /// Invalidates the current logger instance so it can be recreated.
    private static func invalidateLogger() {
        _logger = nil
        _destinations.set(nil)
    }
}

/// Entity used for logging messages.
public class Logger: @unchecked Sendable {
    /// Identifier of the Logger. Will be visible if a destination has `showIdentifiers` enabled.
    public let identifier: String
    
    /// Destinations for this logger.
    /// See `LogDestination` protocol for details.
    @Atomic private var _destinations: [LogDestination]
    public var destinations: [LogDestination] {
        get { _destinations }
        set { _destinations = newValue }
    }

    private let loggerQueue = DispatchQueue(label: "LoggerQueue \(UUID())")
    
    /// Init a logger with a given identifier and destinations.
    public init(identifier: String = "", destinations: [LogDestination] = []) {
        self.identifier = identifier
        _destinations = destinations
    }
    
    /// Allows logger to be called as function.
    /// Transforms, given that `let log = Logger()`, `log.log(.info, "Hello")` to `log(.info, "Hello")` for ease of use.
    ///
    /// - Parameters:
    ///   - level: Log level for this message
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    ///   - message: Message to be logged
    public func callAsFunction(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        error: Error?
    ) {
        log(
            level,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: error
        )
    }
    
    /// Log a message to all enabled destinations.
    /// See  `Logger.destinations` for customizing the output.
    ///
    /// - Parameters:
    ///   - level: Log level for this message
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    ///   - message: Message to be logged
    public func log(
        _ level: LogLevel,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line,
        message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        error: Error?
    ) {
        let resolvedMessage = String(describing: message())
        let resolvedError = error
        let resolvedThreadName = threadName
        let timestamp = Date()
        let loggerIdentifier = identifier
        let destinations = self.destinations

        loggerQueue.async {
            let enabledDestinations = destinations.filter {
                $0.isEnabled(level: level, subsystems: subsystems)
            }
            guard !enabledDestinations.isEmpty else { return }

            let logDetails = LogDetails(
                loggerIdentifier: loggerIdentifier,
                subsystem: subsystems,
                level: level,
                date: timestamp,
                message: resolvedMessage,
                threadName: resolvedThreadName,
                functionName: functionName,
                fileName: fileName,
                lineNumber: lineNumber,
                error: resolvedError
            )

            for destination in enabledDestinations {
                destination.process(logDetails: logDetails)
            }
        }
    }
    
    /// Log an info message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func info(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        log(
            .info,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Log a debug message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func debug(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        log(
            .debug,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Log a warning message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func warning(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        log(
            .warning,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Log an error message.
    ///
    /// - Parameters:
    ///   - message: Message to be logged
    ///   - functionName: Function of the caller
    ///   - fileName: File of the caller
    ///   - lineNumber: Line number of the caller
    public func error(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        error: Error? = nil,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        // If the error isn't conforming to ``ReflectiveStringConvertible`` we
        // wrap it in a ``ClientError`` to provide consistent logging information.
        let error = {
            guard let error, (error as? ReflectiveStringConvertible) == nil else {
                return error
            }
            return ClientError(with: error, fileName, lineNumber)
        }()

        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: message(),
            subsystems: subsystems,
            error: error
        )
    }
    
    /// Performs `Swift.assert` and stops program execution if `condition` evaluated to false. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - condition: The condition to test.
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        guard !condition() else { return }
        if StreamRuntimeCheck.assertionsEnabled {
            Swift.assert(condition(), String(describing: message()), file: fileName, line: lineNumber)
        }
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: "Assert failed: \(message())",
            subsystems: subsystems,
            error: nil
        )
    }
    
    /// Stops program execution with `Swift.assertionFailure`. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - message: A custom message to log if `condition` is evaluated to false.
    public func assertionFailure(
        _ message: @autoclosure () -> Any,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line
    ) {
        if StreamRuntimeCheck.assertionsEnabled {
            Swift.assertionFailure(String(describing: message()), file: fileName, line: lineNumber)
        }
        log(
            .error,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: "Assert failed: \(message())",
            subsystems: subsystems,
            error: nil
        )
    }
}

private extension Logger {
    var threadName: String {
        if Thread.isMainThread {
            return "[main] "
        } else {
            if let threadName = Thread.current.name, !threadName.isEmpty {
                return "[\(threadName)] "
            } else if
                let queueName = String(validatingUTF8: __dispatch_queue_get_label(nil)), !queueName.isEmpty {
                return "[\(queueName)] "
            } else {
                return String(format: "[%p] ", Thread.current)
            }
        }
    }
}

extension Data {
    /// Converts the data into a pretty-printed JSON string. Use only for debug purposes since this operation can be expensive.
    var debugPrettyPrintedJSON: String {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
            return String(data: prettyPrintedData, encoding: .utf8) ?? "Error: Data to String decoding failed."
        } catch {
            return "<not available string representation>"
        }
    }
}

final class AtomicStorage<Element>: @unchecked Sendable {

    private let queue = UnfairQueue()
    private var value: Element

    init(_ initial: Element) { value = initial }

    func get() -> Element { queue.sync { value } }

    func set(_ newValue: Element) { queue.sync { value = newValue } }
}
