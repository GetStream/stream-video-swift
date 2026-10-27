//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EgressResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var broadcasting: Bool
    public var compositeRecording: CompositeRecordingResponse?
    public var frameRecording: FrameRecordingResponse?
    public var hls: EgressHLSResponse?
    public var individualRecording: IndividualRecordingResponse?
    public var rawRecording: RawRecordingResponse?
    public var rtmps: [EgressRTMPResponse]

    public init(
        broadcasting: Bool,
        compositeRecording: CompositeRecordingResponse? = nil,
        frameRecording: FrameRecordingResponse? = nil,
        hls: EgressHLSResponse? = nil,
        individualRecording: IndividualRecordingResponse? = nil,
        rawRecording: RawRecordingResponse? = nil,
        rtmps: [EgressRTMPResponse]
    ) {
        self.broadcasting = broadcasting
        self.compositeRecording = compositeRecording
        self.frameRecording = frameRecording
        self.hls = hls
        self.individualRecording = individualRecording
        self.rawRecording = rawRecording
        self.rtmps = rtmps
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.broadcasting = try container.decode(Bool.self, forKey: .broadcasting)
        self.compositeRecording = try container.decodeIfPresent(CompositeRecordingResponse.self, forKey: .compositeRecording)
        self.frameRecording = try container.decodeIfPresent(FrameRecordingResponse.self, forKey: .frameRecording)
        self.hls = try container.decodeIfPresent(EgressHLSResponse.self, forKey: .hls)
        self.individualRecording = try container.decodeIfPresent(IndividualRecordingResponse.self, forKey: .individualRecording)
        self.rawRecording = try container.decodeIfPresent(RawRecordingResponse.self, forKey: .rawRecording)
        self.rtmps = try container.decode([EgressRTMPResponse].self, forKey: .rtmps)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(broadcasting, forKey: .broadcasting)
        try container.encodeIfPresent(compositeRecording, forKey: .compositeRecording)
        try container.encodeIfPresent(frameRecording, forKey: .frameRecording)
        try container.encodeIfPresent(hls, forKey: .hls)
        try container.encodeIfPresent(individualRecording, forKey: .individualRecording)
        try container.encodeIfPresent(rawRecording, forKey: .rawRecording)
        try container.encode(rtmps, forKey: .rtmps)
    }
}

extension EgressResponse: Hashable {
    public static func == (lhs: EgressResponse, rhs: EgressResponse) -> Bool {
        lhs.broadcasting == rhs.broadcasting &&
            lhs.compositeRecording == rhs.compositeRecording &&
            lhs.frameRecording == rhs.frameRecording &&
            lhs.hls == rhs.hls &&
            lhs.individualRecording == rhs.individualRecording &&
            lhs.rawRecording == rhs.rawRecording &&
            lhs.rtmps == rhs.rtmps
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(broadcasting)
        hasher.combine(compositeRecording)
        hasher.combine(frameRecording)
        hasher.combine(hls)
        hasher.combine(individualRecording)
        hasher.combine(rawRecording)
        hasher.combine(rtmps)
    }
}
