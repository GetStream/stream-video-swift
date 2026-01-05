//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine

extension Publishers {
    /// A Publisher that logs values emitted by an upstream publisher.
    public struct Log<Upstream: Publisher>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        private let upstream: Upstream
        private let level: LogLevel
        private let subsystems: LogSubsystem
        private let functionName: StaticString
        private let fileName: StaticString
        private let lineNumber: UInt
        private let messageBuilder: ((Self.Output) -> String)?

        /// Initializes a new Log publisher.
        ///
        /// - Parameters:
        ///   - upstream: The upstream publisher to log values from.
        ///   - level: The log level to use.
        ///   - subsystems: The subsystem(s) to associate with the log messages.
        ///   - functionName: The name of the function where logging occurs.
        ///   - fileName: The name of the file where logging occurs.
        ///   - lineNumber: The line number where logging occurs.
        ///   - messageBuilder: An optional closure to customize the log message.
        init(
            upstream: Upstream,
            level: LogLevel,
            subsystems: LogSubsystem,
            functionName: StaticString,
            fileName: StaticString,
            lineNumber: UInt,
            messageBuilder: ((Self.Output) -> String)?
        ) {
            self.upstream = upstream
            self.level = level
            self.subsystems = subsystems
            self.functionName = functionName
            self.fileName = fileName
            self.lineNumber = lineNumber
            self.messageBuilder = messageBuilder
        }

        public func receive<S>(
            subscriber: S
        ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            upstream.receive(
                subscriber: LogSubscriber(
                    downstream: subscriber,
                    level: level,
                    subsystems: subsystems,
                    functionName: functionName,
                    fileName: fileName,
                    lineNumber: lineNumber,
                    messageBuilder: messageBuilder
                )
            )
        }
    }
}

/// A custom Subscriber that logs values before passing them downstream.
private final class LogSubscriber<Downstream: Subscriber>: Subscriber {
    typealias Input = Downstream.Input
    typealias Failure = Downstream.Failure

    private let downstream: Downstream
    private let level: LogLevel
    private let subsystems: LogSubsystem
    private let functionName: StaticString
    private let fileName: StaticString
    private let lineNumber: UInt
    private let messageBuilder: ((Input) -> String)?

    init(
        downstream: Downstream,
        level: LogLevel,
        subsystems: LogSubsystem,
        functionName: StaticString,
        fileName: StaticString,
        lineNumber: UInt,
        messageBuilder: ((Input) -> String)?
    ) {
        self.downstream = downstream
        self.level = level
        self.subsystems = subsystems
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.messageBuilder = messageBuilder
    }

    func receive(subscription: Subscription) {
        downstream.receive(subscription: subscription)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        log.log(
            level,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            message: messageBuilder?(input) ?? "\(input)",
            subsystems: subsystems,
            error: nil
        )
        return downstream.receive(input)
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        downstream.receive(completion: completion)
    }
}

extension Publisher {
    /// Logs the publisher's input using Stream Logger
    ///
    /// - Parameters:
    ///   - level: The log level to use.
    ///   - subsystems: The subsystem(s) to associate with the log messages.
    ///   - functionName: The name of the function where logging occurs.
    ///   - fileName: The name of the file where logging occurs.
    ///   - lineNumber: The line number where logging occurs.
    ///   - messageBuilder: An optional closure to customize the log message.
    /// - Returns: A publisher that logs values before passing them downstream.
    public func log(
        _ level: LogLevel,
        subsystems: LogSubsystem = .other,
        functionName: StaticString = #function,
        fileName: StaticString = #fileID,
        lineNumber: UInt = #line,
        messageBuilder: ((Self.Output) -> String)? = nil
    ) -> Publishers.Log<Self> {
        Publishers.Log(
            upstream: self,
            level: level,
            subsystems: subsystems,
            functionName: functionName,
            fileName: fileName,
            lineNumber: lineNumber,
            messageBuilder: messageBuilder
        )
    }
}
