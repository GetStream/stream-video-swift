//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

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
}

public extension ReflectiveStringConvertible {
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
        let mirror = Mirror(reflecting: self)
        var output: [String] = ["Type: \(type(of: self))"]

        let excludedProperties = self.excludedProperties
        mirror
            .children
            .compactMap {
                if let label = $0.label {
                    let value = propertyTransformers[label]?($0.value) ?? $0.value
                    return (label: label, value: value)
                } else {
                    return nil
                }
            }
            .filter { !excludedProperties.contains($0.label) }
            .forEach { output.append(" - \($0.label): \($0.value)") }

        return output.joined(separator: separator)
    }
}
