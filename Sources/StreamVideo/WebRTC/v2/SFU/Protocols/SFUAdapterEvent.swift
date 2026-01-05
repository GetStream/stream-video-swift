//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

/// A protocol defining a traceable event used within the SFU adapter layer.
///
/// Conforming types represent structured events that describe client actions
/// or requests sent to the SFU. Each event includes a hostname for context
/// and a `traceTag` for logging or analytics. Optionally, `traceData` can be
/// provided to supply additional metadata or payload details.
protocol SFUAdapterEvent {
    /// The host address or identifier of the SFU the event targets.
    var hostname: String { get set }

    var traceTag: String { get }

    /// Optional trace payload containing event-specific metadata or data.
    ///
    /// Defaults to `nil` if no additional context is needed for the event.
    var traceData: AnyEncodable? { get }
}

extension SFUAdapterEvent {
    var traceData: AnyEncodable? { nil }
}
