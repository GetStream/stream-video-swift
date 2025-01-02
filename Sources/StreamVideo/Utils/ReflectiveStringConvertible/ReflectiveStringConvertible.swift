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
                    return (label: label, value: $0.value)
                } else {
                    return nil
                }
            }
            .filter { !excludedProperties.contains($0.label) }
            .forEach { output.append(" - \($0.label): \($0.value)") }

        return output.joined(separator: separator)
    }
}
