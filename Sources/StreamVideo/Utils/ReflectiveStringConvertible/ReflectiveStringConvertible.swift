//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enumeration representing rules for skipping properties during reflective
/// string conversion.
///
/// These rules can be used to exclude properties based on specific conditions,
/// such as being empty, nil, or matching a custom rule.
public enum ReflectiveStringConvertibleSkipRule: Hashable {
    /// Skip properties that are empty.
    case empty

    /// Skip properties that are nil.
    case nilValues

    /// Skip properties based on a custom rule.
    ///
    /// - Parameters:
    ///   - identifier: A unique identifier for the custom rule.
    ///   - rule: A closure that takes a `Mirror.Child` and returns a Boolean
    ///     indicating whether the property should be skipped.
    case custom(identifier: String, rule: (Mirror.Child) -> Bool)

    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of
    ///   this instance.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .empty:
            hasher.combine(".empty")
        case .nilValues:
            hasher.combine(".nilValues")
        case let .custom(identifier, _):
            hasher.combine(".custom_")
            hasher.combine(identifier)
        }
    }

    /// Determines whether a given property should be skipped based on the rule.
    ///
    /// - Parameter child: A `Mirror.Child` representing the property to check.
    /// - Returns: A Boolean indicating whether the property should be skipped.
    public func shouldBeSkipped(_ child: Mirror.Child) -> Bool {
        switch self {
        case .empty:
            if (child.value as? String)?.isEmpty == true {
                return true
            } else if (child.value as? (any Collection))?.isEmpty == true {
                return true
            } else {
                return false
            }

        case .nilValues:
            return "\(child.value)" == "nil"

        case let .custom(_, rule):
            return rule(child)
        }
    }

    /// Compares two `ReflectiveStringConvertibleSkipRule` values for equality.
    ///
    /// - Parameters:
    ///   - lhs: A `ReflectiveStringConvertibleSkipRule` value.
    ///   - rhs: Another `ReflectiveStringConvertibleSkipRule` value.
    /// - Returns: A Boolean indicating whether the two values are equal.
    public static func == (
        lhs: ReflectiveStringConvertibleSkipRule,
        rhs: ReflectiveStringConvertibleSkipRule
    ) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.nilValues, .nilValues):
            return true
        case let (.custom(lhsIdentifier, _), .custom(rhsIdentifier, _)) where lhsIdentifier == rhsIdentifier:
            return true
        default:
            return false
        }
    }
}

/// An extension for collections of `ReflectiveStringConvertibleSkipRule` values.
extension Collection where Element == ReflectiveStringConvertibleSkipRule {
    /// Determines whether a given property should be skipped based on the rules
    /// in the collection.
    ///
    /// - Parameter element: A `Mirror.Child` representing the property to check.
    /// - Returns: A Boolean indicating whether the property should be skipped.
    func shouldBeSkipped(_ element: Mirror.Child) -> Bool {
        reduce(false) { partialResult, rule in
            guard !partialResult else { return partialResult }
            return rule.shouldBeSkipped(element)
        }
    }
}

/// A protocol that extends `CustomStringConvertible` to provide reflective string conversion capabilities.
///
/// Types conforming to this protocol can customize their string representation by excluding specific properties
/// and leveraging Swift's reflection capabilities.
public protocol ReflectiveStringConvertible: CustomStringConvertible {
    /// The separator used to join different parts of the string representation.
    var separator: String { get }

    /// A set of property names to be excluded from the string representation.
    var excludedProperties: Set<String> { get }

    /// A set of property names to be transformed during the string representation.
    var propertyTransformers: [String: (Any) -> String] { get }

    var skipRuleSet: Set<ReflectiveStringConvertibleSkipRule> { get }
}

public extension ReflectiveStringConvertible {
    var skipRuleSet: Set<ReflectiveStringConvertibleSkipRule> {
        [.empty, .nilValues]
    }

    /// The default separator used to join different parts of the string representation.
    ///
    /// By default, this is set to a newline character ("\n").
    var separator: String { "\n" }

    /// The default set of properties to be excluded from the string representation.
    ///
    /// By default, this includes the "unknownFields" property.
    var excludedProperties: Set<String> {
        [
            "unknownFields"
        ]
    }

    /// A dictionary of custom transformation functions for specific properties in the string representation.
    ///
    /// Each key in the dictionary corresponds to the name of a property that requires a custom transformation.
    /// The associated value is a closure that takes the property value (`Any`) and returns a transformed `String`.
    ///
    /// The transformed string will be included in the final description of the object.
    ///
    /// By default, this includes a transformation for the `sdp` property, which replaces carriage return (`\r\n`)
    /// characters with newline (`\n`) characters.
    ///
    /// - Example:
    ///   Suppose you have a property `sdp` that contains a multiline string with carriage return characters (`\r\n`).
    ///   You can use this transformer to normalize the line endings before including it in the description:
    ///   ```
    ///   "sdp": { "\($0)".replacingOccurrences(of: "\r\n", with: "\n") }
    ///   ```
    ///
    /// - Returns: A dictionary mapping property names to their respective transformation closures.
    var propertyTransformers: [String: (Any) -> String] {
        [
            "sdp": { "\($0)".replacingOccurrences(of: "\r\n", with: "\n") }
        ]
    }

    /// Generates a string representation of the conforming type using reflection.
    ///
    /// This implementation creates a detailed description of the object, including its type
    /// and all non-excluded properties with their values.
    ///
    /// - Returns: A string representation of the object.
    var description: String {
        #if STREAM_TESTS
        // During tests we allow full error logging.
        #else
        guard LogConfig.level == .debug else {
            return "\(type(of: self))"
        }
        #endif
        let mirror = Mirror(reflecting: self)
        var output: [String] = ["Type: \(type(of: self))"]

        let excludedProperties = self.excludedProperties
        mirror
            .children
            .filter { !skipRuleSet.shouldBeSkipped($0) }
            .compactMap {
                if let label = $0.label, !excludedProperties.contains(label) {
                    let value = propertyTransformers[label]?($0.value) ?? $0.value
                    return (label: label, value: value)
                } else {
                    return nil
                }
            }
            .forEach { (child: (label: String, value: Any)) in
                output.append(" - \(child.label): \(child.value)")
            }

        return output.joined(separator: separator)
    }
}
