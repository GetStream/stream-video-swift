//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class AppEventResponse: @unchecked Sendable, Decodable {
    /// boolean
    public var asyncUrlEnrichEnabled: Bool?
    /// boolean
    public var autoTranslationEnabled: Bool
    public var fileUploadConfig: FileUploadConfig?
    public var imageUploadConfig: FileUploadConfig?
    /// string
    public var name: String

    public init(
        asyncUrlEnrichEnabled: Bool? = nil,
        autoTranslationEnabled: Bool,
        fileUploadConfig: FileUploadConfig? = nil,
        imageUploadConfig: FileUploadConfig? = nil,
        name: String
    ) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.autoTranslationEnabled = autoTranslationEnabled
        self.fileUploadConfig = fileUploadConfig
        self.imageUploadConfig = imageUploadConfig
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.asyncUrlEnrichEnabled = try container.decodeIfPresent(Bool.self, forKey: .asyncUrlEnrichEnabled)
        self.autoTranslationEnabled = try container.decode(Bool.self, forKey: .autoTranslationEnabled)
        self.fileUploadConfig = try container.decodeIfPresent(FileUploadConfig.self, forKey: .fileUploadConfig)
        self.imageUploadConfig = try container.decodeIfPresent(FileUploadConfig.self, forKey: .imageUploadConfig)
        self.name = try container.decode(String.self, forKey: .name)
    }
}

extension AppEventResponse: Hashable {
    public static func == (lhs: AppEventResponse, rhs: AppEventResponse) -> Bool {
        lhs.asyncUrlEnrichEnabled == rhs.asyncUrlEnrichEnabled &&
            lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.fileUploadConfig == rhs.fileUploadConfig &&
            lhs.imageUploadConfig == rhs.imageUploadConfig &&
            lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(asyncUrlEnrichEnabled)
        hasher.combine(autoTranslationEnabled)
        hasher.combine(fileUploadConfig)
        hasher.combine(imageUploadConfig)
        hasher.combine(name)
    }
}
