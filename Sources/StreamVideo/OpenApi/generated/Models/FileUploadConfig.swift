//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class FileUploadConfig: @unchecked Sendable, Codable, JSONEncodable {
    public var allowedFileExtensions: [String]
    public var allowedMimeTypes: [String]
    public var blockedFileExtensions: [String]
    public var blockedMimeTypes: [String]
    public var sizeLimit: Int

    public init(
        allowedFileExtensions: [String],
        allowedMimeTypes: [String],
        blockedFileExtensions: [String],
        blockedMimeTypes: [String],
        sizeLimit: Int
    ) {
        self.allowedFileExtensions = allowedFileExtensions
        self.allowedMimeTypes = allowedMimeTypes
        self.blockedFileExtensions = blockedFileExtensions
        self.blockedMimeTypes = blockedMimeTypes
        self.sizeLimit = sizeLimit
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.allowedFileExtensions = try container.decode([String].self, forKey: .allowedFileExtensions)
        self.allowedMimeTypes = try container.decode([String].self, forKey: .allowedMimeTypes)
        self.blockedFileExtensions = try container.decode([String].self, forKey: .blockedFileExtensions)
        self.blockedMimeTypes = try container.decode([String].self, forKey: .blockedMimeTypes)
        self.sizeLimit = try container.decode(Int.self, forKey: .sizeLimit)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(allowedFileExtensions, forKey: .allowedFileExtensions)
        try container.encode(allowedMimeTypes, forKey: .allowedMimeTypes)
        try container.encode(blockedFileExtensions, forKey: .blockedFileExtensions)
        try container.encode(blockedMimeTypes, forKey: .blockedMimeTypes)
        try container.encode(sizeLimit, forKey: .sizeLimit)
    }
}

extension FileUploadConfig: Hashable {
    public static func == (lhs: FileUploadConfig, rhs: FileUploadConfig) -> Bool {
        lhs.allowedFileExtensions == rhs.allowedFileExtensions &&
            lhs.allowedMimeTypes == rhs.allowedMimeTypes &&
            lhs.blockedFileExtensions == rhs.blockedFileExtensions &&
            lhs.blockedMimeTypes == rhs.blockedMimeTypes &&
            lhs.sizeLimit == rhs.sizeLimit
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(allowedFileExtensions)
        hasher.combine(allowedMimeTypes)
        hasher.combine(blockedFileExtensions)
        hasher.combine(blockedMimeTypes)
        hasher.combine(sizeLimit)
    }
}
