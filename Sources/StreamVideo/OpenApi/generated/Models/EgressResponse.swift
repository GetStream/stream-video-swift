//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class EgressResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var broadcasting: Bool
    public var compositeRecording: CompositeRecordingResponse?
    public var frameRecording: FrameRecordingResponse?
    public var hls: EgressHLSResponse?
    public var individualRecording: IndividualRecordingResponse?
    public var rawRecording: RawRecordingResponse?
    public var rtmps: [EgressRTMPResponse]

    public init(broadcasting: Bool, compositeRecording: CompositeRecordingResponse? = nil, frameRecording: FrameRecordingResponse? = nil, hls: EgressHLSResponse? = nil, individualRecording: IndividualRecordingResponse? = nil, rawRecording: RawRecordingResponse? = nil, rtmps: [EgressRTMPResponse]) {
        self.broadcasting = broadcasting
        self.compositeRecording = compositeRecording
        self.frameRecording = frameRecording
        self.hls = hls
        self.individualRecording = individualRecording
        self.rawRecording = rawRecording
        self.rtmps = rtmps
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case broadcasting
    case compositeRecording = "composite_recording"
    case frameRecording = "frame_recording"
    case hls
    case individualRecording = "individual_recording"
    case rawRecording = "raw_recording"
    case rtmps
}

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
