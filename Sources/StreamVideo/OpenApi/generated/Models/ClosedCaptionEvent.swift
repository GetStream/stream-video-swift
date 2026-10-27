//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when closed captions are being sent in a call, clients should use this to show the closed captions in the call screen
public final class ClosedCaptionEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    /// CallClosedCaption represents a closed caption of a call.
    public var closedCaption: CallClosedCaption
    public var createdAt: Date
    /// The type of event: "call.closed_caption" in this case
    public var type: String = "call.closed_caption"

    public init(callCid: String, closedCaption: CallClosedCaption, createdAt: Date) {
        self.callCid = callCid
        self.closedCaption = closedCaption
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.closedCaption = try container.decode(CallClosedCaption.self, forKey: .closedCaption)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension ClosedCaptionEvent: Hashable {
    public static func == (lhs: ClosedCaptionEvent, rhs: ClosedCaptionEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.closedCaption == rhs.closedCaption &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(closedCaption)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
