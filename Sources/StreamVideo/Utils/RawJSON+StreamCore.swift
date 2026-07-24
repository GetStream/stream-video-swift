//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public extension RawJSON {
    /// Extracts the wrapped value as the specified type, if possible.
    func value<T>() -> T? {
        switch self {
        case let .number(double):
            if T.self == Int.self { return Int(double) as? T }
            if T.self == Int32.self { return Int32(double) as? T }
            if T.self == Int64.self { return Int64(double) as? T }
            if T.self == UInt.self { return UInt(double) as? T }
            if T.self == UInt32.self { return UInt32(double) as? T }
            if T.self == UInt64.self { return UInt64(double) as? T }
            if T.self == Double.self { return double as? T }
            if T.self == Float.self { return Float(double) as? T }
            return double as? T
        case let .string(string):
            return string as? T
        case let .bool(bool):
            return bool as? T
        case let .dictionary(dictionary):
            return dictionary as? T
        case let .array(array):
            return array as? T
        case .nil:
            return nil
        @unknown default:
            return nil
        }
    }

    /// Extracts the wrapped value as the specified type, or returns a fallback.
    func value<T>(fallback: T) -> T {
        value() ?? fallback
    }
}

extension RawJSON {
    init(_ object: NSObject) {
        switch object {
        case let string as NSString:
            self = .string(string as String)
        case let number as NSNumber:
            self = .number(number.doubleValue)
        case let array as NSArray:
            self = .array(
                array.compactMap {
                    guard let object = $0 as? NSObject else { return nil }
                    return .init(object)
                }
            )
        case let dictionary as NSDictionary:
            self = .dictionary(
                dictionary.reduce(into: [:]) { result, element in
                    guard let key = element.key as? String,
                          let value = element.value as? NSObject
                    else {
                        return
                    }
                    result[key] = .init(value)
                }
            )
        default:
            self = .string(object.description)
        }
    }
}
