//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A `RawJSON` type.
/// Used to store and operate objects of unknown structure that's not possible to decode.
/// https://forums.swift.org/t/new-unevaluated-type-for-decoder-to-allow-later-re-encoding-of-data-with-unknown-structure/11117
public indirect enum RawJSON: Codable, Hashable, Sendable {
    case number(Double)
    case string(String)
    case bool(Bool)
    case dictionary([String: RawJSON])
    case array([RawJSON])
    case `nil`

    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        if let value = try? singleValueContainer.decode(Bool.self) {
            self = .bool(value)
            return
        } else if let value = try? singleValueContainer.decode(String.self) {
            self = .string(value)
            return
        } else if let value = try? singleValueContainer.decode(Double.self) {
            self = .number(value)
            return
        } else if let value = try? singleValueContainer.decode([String: RawJSON].self) {
            self = .dictionary(value)
            return
        } else if let value = try? singleValueContainer.decode([RawJSON].self) {
            self = .array(value)
            return
        } else if singleValueContainer.decodeNil() {
            self = .nil
            return
        }
        throw DecodingError
            .dataCorrupted(
                DecodingError
                    .Context(codingPath: decoder.codingPath, debugDescription: "Could not find reasonable type to map to JSONValue")
            )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .number(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .string(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .dictionary(value): try container.encode(value)
        case .nil: try container.encodeNil()
        }
    }
}

// MARK: Raw Values Helpers

public extension RawJSON {
    /// Extracts a number value of RawJSON.
    /// Returns nil if the value is not a number.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let price = customData["price"]?.numberValue ?? 0
    /// ```
    var numberValue: Double? {
        guard case let .number(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a string value of RawJSON.
    /// Returns nil if the value is not a string.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let email = customData["email"]?.stringValue ?? ""
    /// ```
    var stringValue: String? {
        guard case let .string(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a bool value of RawJSON.
    /// Returns nil if the value is not a bool.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let isManager = customData["isManager"]?.boolValue ?? false
    /// ```
    var boolValue: Bool? {
        guard case let .bool(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a dictionary value of RawJSON.
    /// Returns nil if the value is not a dictionary.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let flightPrice = customData["flight"]?.dictionaryValue?["price"]?.numberValue ?? 0
    /// ```
    var dictionaryValue: [String: RawJSON]? {
        guard case let .dictionary(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts an array value of RawJSON.
    /// Returns nil if the value is not an array.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let flights: [RawJSON]? = customData["flights"]?.arrayValue
    /// ```
    var arrayValue: [RawJSON]? {
        guard case let .array(value) = self else {
            return nil
        }
        return value
    }

    /// Extracts a number array of RawJSON.
    /// Returns nil if the value is not an array of numbers.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let ages = customData["ages"]?.numberArrayValue ?? []
    /// ```
    var numberArrayValue: [Double]? {
        guard let rawArrayValue = arrayValue else {
            return nil
        }

        return rawArrayValue.compactMap(\.numberValue)
    }

    /// Extracts a string array of RawJSON.
    /// Returns nil if the value is not an array of strings.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let names = customData["names"]?.stringArrayValue ?? []
    /// ```
    var stringArrayValue: [String]? {
        guard let rawArrayValue = arrayValue else {
            return nil
        }

        return rawArrayValue.compactMap(\.stringValue)
    }

    /// Extracts a bool array of RawJSON.
    /// Returns nil if the value is not an array of bools.
    var boolArrayValue: [Bool]? {
        guard let rawArrayValue = arrayValue else {
            return nil
        }

        return rawArrayValue.compactMap(\.boolValue)
    }

    /// Checks if the RawJSON value is null.
    var isNil: Bool {
        switch self {
        case .nil:
            return true
        default:
            return false
        }
    }

    /// Extracts the wrapped value as the specified type, if possible.
    ///
    /// This method tries to cast the underlying RawJSON value to the requested
    /// generic type `T`. Returns `nil` if the wrapped value does not match the
    /// requested type.
    ///
    /// Example:
    /// ```
    /// let json: RawJSON = .string("hello")
    /// let value: String? = json.value()
    /// ```
    ///
    /// - Returns: The value as type `T` if compatible, otherwise `nil`.
    func value<T>() -> T? {
        switch self {
        case let .number(double):
            // Handle all integer and floating-point conversions
            if T.self == Int.self { return Int(double) as? T }
            if T.self == Int32.self { return Int32(double) as? T }
            if T.self == Int64.self { return Int64(double) as? T }
            if T.self == UInt.self { return UInt(double) as? T }
            if T.self == UInt32.self { return UInt32(double) as? T }
            if T.self == UInt64.self { return UInt64(double) as? T }
            if T.self == Double.self { return double as? T }
            if T.self == Float.self { return Float(double) as? T }
            // Fall back to cast (may work for NSNumber, etc)
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
        }
    }

    /// Extracts the wrapped value as the specified type, or returns a fallback.
    ///
    /// This method tries to cast the underlying RawJSON value to the requested
    /// generic type `T`. If the cast fails, the `fallback` value is returned.
    ///
    /// Example:
    /// ```
    /// let json: RawJSON = .number(42.0)
    /// let value: Int = json.value(fallback: 0) // returns 0, as the value is a Double
    /// ```
    ///
    /// - Parameter fallback: The value to return if the cast fails.
    /// - Returns: The value as type `T` if compatible, otherwise the fallback.
    func value<T>(fallback: T) -> T {
        value() ?? fallback
    }
}

// MARK: ExpressibleByLiteral

extension RawJSON: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = RawJSON

    /// RawJSON can be created by using a Dictionary Literal.
    ///
    /// Example:
    /// ```
    /// let customData: [String: RawJSON] = [
    ///     "flight": [
    ///         "price": .number(1000),
    ///         "destination": .string("Lisbon")
    ///     ]
    /// ]
    /// ```
    public init(dictionaryLiteral elements: (String, RawJSON)...) {
        let dict: [String: RawJSON] = elements.reduce(into: [:]) { partialResult, element in
            partialResult[element.0] = element.1
        }
        self = .dictionary(dict)
    }
}

extension RawJSON: ExpressibleByArrayLiteral {
    /// RawJSON can be created by using an Array Literal.
    ///
    /// Example:
    /// ```
    /// let customData: [String: RawJSON] = [
    ///     "names": [.string("John"), string("Doe")]
    /// ]
    /// ```
    public init(arrayLiteral elements: RawJSON...) {
        self = .array(elements)
    }
}

extension RawJSON: ExpressibleByStringLiteral {
    /// RawJSON can be created by using a String Literal.
    ///
    /// Example:
    /// ```
    /// let customData: [String: RawJSON] = [
    ///     "names": ["John", "Doe"] // instead of [.string("John"), .string("Doe")]
    /// ]
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension RawJSON: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    /// RawJSON can be created by using a Float Literal.
    ///
    /// Example:
    /// ```
    /// let customData: [String: RawJSON] = [
    ///     "distances": [3.5, 4.5] // instead of [.number(3.5), .number(3.5)]
    /// ]
    /// ```
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(value)
    }

    /// RawJSON can be created by using an Integer Literal.
    ///
    /// Example:
    /// ```
    /// let customData: [String: RawJSON] = [
    ///     "ages": [23, 32] // instead of [.number(23.0), .number(32.0)]
    /// ]
    /// ```
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Double(value))
    }
}

extension RawJSON: ExpressibleByBooleanLiteral {
    /// RawJSON can be created by using a Bool Literal.
    ///
    /// Example:
    /// ```
    /// let customData: [String: RawJSON] = [
    ///     "isManager": true // instead of .bool(true)
    /// ]
    /// ```
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

// MARK: Subscripts

extension RawJSON {
    /// Accesses the RawJSON as a dictionary with the given key for reading and writing.
    /// This is specially useful for accessing nested types inside the extra data dictionary.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let price = customData["flight"]?["price"].numberValue
    /// let destination = customData["flight"]?["destination"].stringValue
    /// ```
    subscript(key: String) -> RawJSON? {
        get {
            guard case let .dictionary(dict) = self else {
                return nil
            }

            return dict[key]
        }
        set {
            guard case var .dictionary(dict) = self else {
                return
            }

            dict[key] = newValue
            self = .dictionary(dict)
        }
    }

    /// Accesses RawJSON as an array and accesses the element at the specified position.
    /// This is specially useful for accessing arrays of nested types inside the extra data dictionary.
    ///
    /// Example:
    /// ```
    /// let customData = message.customData
    /// let secondFlightPrice = customData["flights"]?[1]?["price"] ?? 0
    /// ```
    subscript(index: Int) -> RawJSON? {
        get {
            guard case let .array(array) = self else {
                return nil
            }

            return array[index]
        }
        set {
            guard case var .array(array) = self, let newValue = newValue else {
                return
            }

            array[index] = newValue
            self = .array(array)
        }
    }
}

extension RawJSON {
    /// Initializes a `RawJSON` value from an `NSObject`.
    ///
    /// This is useful for converting Foundation types (e.g., from `NSDictionary`,
    /// `NSArray`, `NSNumber`) into strongly typed `RawJSON` enums.
    init(_ object: NSObject) {
        switch object {
        /// Converts NSString into a `.string` RawJSON value.
        case let str as NSString:
            self = .string(str as String)
        /// Converts NSNumber into a `.number` RawJSON value.
        case let num as NSNumber:
            self = .number(num.doubleValue)
        /// Converts NSArray into a `.array` of recursively converted RawJSON.
        case let arr as NSArray:
            let mappedArray = arr.compactMap { elem -> RawJSON? in
                guard let elem = elem as? NSObject else { return nil }
                return .init(elem)
            }
            self = .array(mappedArray)
        /// Converts NSDictionary into a `.dictionary` of recursively converted RawJSON.
        case let dict as NSDictionary:
            var mappedDict = [String: RawJSON]()
            dict.forEach { key, value in
                if let keyStr = key as? String, let valueObj = value as? NSObject {
                    mappedDict[keyStr] = .init(valueObj)
                }
            }
            self = .dictionary(mappedDict)
        /// Fallback: uses the object's description as a `.string`.
        default:
            self = .string(object.description)
        }
    }
}
