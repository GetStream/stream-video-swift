//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class AppEventResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var asyncUrlEnrichEnabled: Bool?
    public var autoTranslationEnabled: Bool
    public var fileUploadConfig: FileUploadConfig?
    public var imageUploadConfig: FileUploadConfig?
    public var name: String

    public init(asyncUrlEnrichEnabled: Bool? = nil, autoTranslationEnabled: Bool, fileUploadConfig: FileUploadConfig? = nil, imageUploadConfig: FileUploadConfig? = nil, name: String) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.autoTranslationEnabled = autoTranslationEnabled
        self.fileUploadConfig = fileUploadConfig
        self.imageUploadConfig = imageUploadConfig
        self.name = name
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
    case autoTranslationEnabled = "auto_translation_enabled"
    case fileUploadConfig = "file_upload_config"
    case imageUploadConfig = "image_upload_config"
    case name
}

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
