//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the video duration to textual representation.
public protocol MediaDurationFormatter {
    func format(_ time: TimeInterval) -> String?
}

/// The default video duration formatter.
open class StreamMediaDurationFormatter: MediaDurationFormatter {
    public var withHoursDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    public var withoutHoursDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    public init() {}

    open func format(_ time: TimeInterval) -> String? {
        let dateComponentsFormatter = time < 3600
            ? withoutHoursDateComponentsFormatter
            : withHoursDateComponentsFormatter
        return dateComponentsFormatter.string(from: time)
    }
}
