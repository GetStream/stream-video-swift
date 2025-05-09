//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A statistics report representing WebRTC internal data, such as track or
/// codec reports, with associated timestamp and key-value details.
struct MutableRTCStatistics: Codable, Equatable {
    enum CodableValue: Codable, Equatable {
        case string(String)
        case double(Double)
        case int(Int)
        case float(Float)
        case array([CodableValue])
        case dictionary([String: CodableValue])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                self = .string(str)
            } else if let num = try? container.decode(Double.self) {
                self = .double(num)
            } else if let num = try? container.decode(Int.self) {
                self = .int(num)
            } else if let num = try? container.decode(Float.self) {
                self = .float(num)
            } else if let arr = try? container.decode([CodableValue].self) {
                self = .array(arr)
            } else if let dict = try? container.decode([String: CodableValue].self) {
                self = .dictionary(dict)
            } else {
                throw DecodingError.typeMismatch(
                    CodableValue.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unsupported value type"
                    )
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .string(str):
                try container.encode(str)
            case let .double(num):
                try container.encode(num)
            case let .int(num):
                try container.encode(num)
            case let .float(num):
                try container.encode(num)
            case let .array(arr):
                try container.encode(arr)
            case let .dictionary(dict):
                try container.encode(dict)
            }
        }

        init(_ object: NSObject) {
            switch object {
            case let str as NSString:
                self = .string(str as String)
            case let num as NSNumber:
                self = .double(num.doubleValue)
            case let arr as NSArray:
                let mappedArray = arr.compactMap { elem -> CodableValue? in
                    guard let elem = elem as? NSObject else { return nil }
                    return .init(elem)
                }
                self = .array(mappedArray)
            case let dict as NSDictionary:
                var mappedDict = [String: CodableValue]()
                dict.forEach { key, value in
                    if let keyStr = key as? String, let valueObj = value as? NSObject {
                        mappedDict[keyStr] = .init(valueObj)
                    }
                }
                self = .dictionary(mappedDict)
            default:
                self = .string(object.description)
            }
        }
    }

    var timestamp: TimeInterval
    var type: String
    var values: [String: CodableValue]

    init(_ source: RTCStatistics) {
        timestamp = source.timestamp_us / 1000
        type = source.type
        var values = [String: CodableValue]()
        source
            .values
            .forEach { values[$0.key] = .init($0.value) }
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)

        var values = [String: CodableValue]()
        for key in container.allKeys {
            if key.stringValue != CodingKeys.timestamp.stringValue,
               key.stringValue != CodingKeys.type.stringValue {
                let value = try container.decode(CodableValue.self, forKey: key)
                values[key.stringValue] = value
            }
        }
        self.values = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)

        for (key, value) in values {
            let dynamicKey = CodingKeys(stringValue: key)!
            try container.encode(value, forKey: dynamicKey)
        }
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }

        static let timestamp = CodingKeys(stringValue: "timestamp")!
        static let type = CodingKeys(stringValue: "type")!
    }
}

extension RTCStatistics {
    var mutable: MutableRTCStatistics {
        .init(self)
    }
}
