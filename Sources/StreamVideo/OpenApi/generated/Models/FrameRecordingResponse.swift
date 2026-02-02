import Foundation

public final class FrameRecordingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var status: String

    public init(status: String) {
        self.status = status
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case status
}

    public static func == (lhs: FrameRecordingResponse, rhs: FrameRecordingResponse) -> Bool {
        lhs.status == rhs.status
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(status)
    }
}
