//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// StreamVideo's logging types are provided by StreamCore. These aliases expose
// them under their historical StreamVideo names so existing call sites keep
// working module-wide without importing StreamCore in every file.

public typealias LogLevel = StreamCore.LogLevel
public typealias LogSubsystem = StreamCore.LogSubsystem
public typealias LogDetails = StreamCore.LogDetails
public typealias LogDestination = StreamCore.LogDestination
public typealias BaseLogDestination = StreamCore.BaseLogDestination
public typealias ConsoleLogDestination = StreamCore.ConsoleLogDestination
@available(iOS 14.0, *)
public typealias OSLogDestination = StreamCore.OSLogDestination
public typealias LogFormatter = StreamCore.LogFormatter
public typealias PrefixLogFormatter = StreamCore.PrefixLogFormatter
public typealias LogConfig = StreamCore.LogConfig
public typealias Logger = StreamCore.Logger

/// The shared logger instance used across the SDK.
public var log: StreamCore.Logger { StreamCore.LogConfig.logger }

extension LogSubsystem {
    /// Default logging subsystem for StreamVideo APIs.
    ///
    /// Declared in StreamVideo (not StreamCore) so it can be used as a default
    /// argument value in files that do not import StreamCore. Equivalent to
    /// `.other`.
    public static let videoDefault = LogSubsystem.other
}
