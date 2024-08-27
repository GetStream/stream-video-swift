//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct AppResponseFields: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var asyncUrlEnrichEnabled: Bool
    public var autoTranslationEnabled: Bool
    public var fileUploadConfig: FileUploadConfig
    public var imageUploadConfig: FileUploadConfig
    public var moderationEnabled: Bool
    public var name: String
    public var videoProvider: String

    public init(
        asyncUrlEnrichEnabled: Bool,
        autoTranslationEnabled: Bool,
        fileUploadConfig: FileUploadConfig,
        imageUploadConfig: FileUploadConfig,
        moderationEnabled: Bool,
        name: String,
        videoProvider: String
    ) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.autoTranslationEnabled = autoTranslationEnabled
        self.fileUploadConfig = fileUploadConfig
        self.imageUploadConfig = imageUploadConfig
        self.moderationEnabled = moderationEnabled
        self.name = name
        self.videoProvider = videoProvider
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        case autoTranslationEnabled = "auto_translation_enabled"
        case fileUploadConfig = "file_upload_config"
        case imageUploadConfig = "image_upload_config"
        case moderationEnabled = "moderation_enabled"
        case name
        case videoProvider = "video_provider"
    }
}
