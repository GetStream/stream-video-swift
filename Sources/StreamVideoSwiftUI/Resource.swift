//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

/// A structure representing a resource with a name and optional file extension.
///
/// `Resource` is used to represent audio, image, or other types of resources in the
/// StreamVideoUI framework. It supports initialization from string literals in the
/// format "name.extension".
///
/// ## Usage
///
/// ```swift
/// // Initialize with name and extension
/// let resource = Resource(name: "outgoing", extension: "m4a")
///
/// // Initialize from string literal
/// let resource: Resource = "outgoing.m4a"
/// ```
public struct Resource: ExpressibleByStringLiteral {
    /// The name of the resource without the file extension.
    public var name: String

    /// The file extension of the resource, if any.
    public var `extension`: String?

    public var fileName: String {
        var components = [name]
        if let fileExtension = self.extension {
            components.append(fileExtension)
        }
        return components.joined(separator: ".")
    }

    /// Creates a new resource with the specified name and optional extension.
    ///
    /// - Parameters:
    ///   - name: The name of the resource.
    ///   - extension: The file extension of the resource.
    public init(name: String, extension: String? = nil) {
        self.name = name
        self.extension = `extension`
    }

    /// Creates a new resource from a string literal.
    ///
    /// The string literal should be in the format "name.extension" where the
    /// extension is optional.
    ///
    /// - Parameter value: The string literal to parse.
    public init(stringLiteral value: StringLiteralType) {
        guard !value.hasPrefix(".") else {
            log.warning("Resource name cannot start with `.`")
            name = ""
            return
        }

        let components = value.split(separator: ".").map { String($0) }

        guard !components.isEmpty else {
            log.warning("Resource name cannot be empty.")
            name = ""
            return
        }

        switch components.count {
        case 1:
            name = components[0]
        case 2:
            name = components[0]
            self.extension = components[1]
        default:
            name = components.dropLast().joined(separator: ".")
            self.extension = components.last
        }
    }
}
