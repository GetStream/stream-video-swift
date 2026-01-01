//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

/// This file defines the `SelectiveEncodable` protocol and its default
/// implementation, enabling selective encoding of properties for types
/// conforming to `Encodable`. Properties can be excluded based on custom
/// rules, such as ignoring those with specific prefixes or names.

import Foundation

/// A protocol that provides a generic way to encode only selected properties
/// of a type conforming to `Encodable`.
///
/// Types conforming to `SelectiveEncodable` automatically encode all their
/// properties except those filtered out by customizable ignore rules. This
/// is useful for excluding internal or transient properties from encoding
/// without manually writing `encode(to:)`.
///
/// The default implementation ignores properties whose names start with a
/// specific prefix (e.g., `-`) or whose names are exactly `unknownFields`.
/// Conforming types can override the `ignorePropertiesRules` property to
/// provide custom filtering rules.
///
/// Usage:
/// - Conform your type to `SelectiveEncodable` instead of `Encodable`.
/// - Optionally override `ignorePropertiesRules` to customize which property
///   names to ignore during encoding.
/// - The encoding process reflects on the instance's properties and encodes
///   only those not matching any ignore rule.
///
/// Note:
/// - Properties must themselves conform to `Encodable` to be encoded.
/// - This protocol uses reflection and may have performance implications
///   compared to manual encoding.
protocol SelectiveEncodable: Encodable {
    var encodableRepresentation: any Encodable { get }

    /// A type alias for a closure that takes a property name and returns
    /// whether it should be ignored during encoding.
    typealias IgnoreRule = (String) -> Bool

    /// An array of rules used to determine which properties to ignore.
    ///
    /// Each rule is a closure that receives a property name and returns
    /// `true` if the property should be excluded from encoding.
    ///
    /// By default, this includes ignoring properties named `unknownFields`
    /// and those starting with a hyphen (`-`).
    var ignorePropertiesRules: [IgnoreRule] { get }
}

extension SelectiveEncodable {
    var encodableRepresentation: any Encodable { self }

    /// Default ignore rules for property names.
    ///
    /// Properties named `unknownFields` or starting with `-` are ignored.
    var ignorePropertiesRules: [IgnoreRule] {
        [
            { $0 == "unknownFields" },
            { $0.hasPrefix("-") }
        ]
    }

    /// Determines whether a property with the given label should be ignored.
    ///
    /// Evaluates each ignore rule in order and returns `true` if any rule
    /// matches the label.
    ///
    /// - Parameter label: The property name to check.
    /// - Returns: `true` if the property should be ignored, `false` otherwise.
    func shouldIgnoreProperty(_ label: String) -> Bool {
        // If there are no rules, do not ignore any property.
        guard !ignorePropertiesRules.isEmpty else {
            return false
        }
        // Check each rule; stop and return true if any rule matches.
        return ignorePropertiesRules.reduce(false) { partialResult, rule in
            guard !partialResult else {
                // Already matched a rule, no need to check further.
                return partialResult
            }
            return rule(label)
        }
    }

    /// Encodes the properties of `self` selectively according to the ignore rules.
    ///
    /// Uses reflection to iterate over all stored properties and encodes only
    /// those not ignored. Each property is encoded by obtaining a super encoder
    /// keyed by the property name.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: Rethrows any encoding errors from the properties.
    func encode(to encoder: Encoder) throws {
        // Create a keyed container using a generic coding key type.
        var container = encoder.container(keyedBy: SelectiveEncodableCodingKeys.self)
        // Reflect on self to access all stored properties.
        let mirror = Mirror(reflecting: encodableRepresentation)

        // Iterate over each child property.
        for child in mirror.children {
            do {
                try process(child, container: &container)
            } catch {
                log.warning("Unable to json encode property:\(child.label) on type:\(type(of: self)).")
            }
        }
    }

    private func process(
        _ child: Mirror.Child,
        container: inout KeyedEncodingContainer<SelectiveEncodableCodingKeys>
    ) throws {
        guard
            let label = child.label,
            // Skip properties without a label or those that should be ignored.
            !shouldIgnoreProperty(label),
            // Construct a coding key from the property name.
            let codingKey = SelectiveEncodableCodingKeys(stringValue: label),
            // Attempt to encode the property value if it conforms to Encodable.
            let value = child.value as? Encodable
        else {
            return
        }

        try value.encode(to: container.superEncoder(forKey: codingKey))
    }
}

/// A generic `CodingKey` implementation used for dynamic property encoding.
///
/// This struct allows encoding properties by their string names without
/// requiring predefined enum cases. It supports string keys but not integer keys.
struct SelectiveEncodableCodingKeys: CodingKey {
    /// The string representation of the coding key.
    var stringValue: String
    /// Integer representation is not supported; always returns nil.
    var intValue: Int? { nil }
    /// Initializes a coding key from a string value.
    ///
    /// - Parameter stringValue: The string to use as the key.
    init?(stringValue: String) { self.stringValue = stringValue }
    /// Initialization from integer value is not supported.
    ///
    /// - Parameter intValue: The integer value (ignored).
    /// - Returns: Always nil.
    init?(intValue: Int) { nil }
}
