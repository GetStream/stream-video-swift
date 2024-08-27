//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetOGResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var actions: [Action?]? = nil
    public var assetUrl: String? = nil
    public var authorIcon: String? = nil
    public var authorLink: String? = nil
    public var authorName: String? = nil
    public var color: String? = nil
    public var custom: [String: RawJSON]
    public var duration: String
    public var fallback: String? = nil
    public var fields: [Field?]? = nil
    public var footer: String? = nil
    public var footerIcon: String? = nil
    public var giphy: Images? = nil
    public var imageUrl: String? = nil
    public var ogScrapeUrl: String? = nil
    public var originalHeight: Int? = nil
    public var originalWidth: Int? = nil
    public var pretext: String? = nil
    public var text: String? = nil
    public var thumbUrl: String? = nil
    public var title: String? = nil
    public var titleLink: String? = nil
    public var type: String? = nil

    public init(
        actions: [Action?]? = nil,
        assetUrl: String? = nil,
        authorIcon: String? = nil,
        authorLink: String? = nil,
        authorName: String? = nil,
        color: String? = nil,
        custom: [String: RawJSON],
        duration: String,
        fallback: String? = nil,
        fields: [Field?]? = nil,
        footer: String? = nil,
        footerIcon: String? = nil,
        giphy: Images? = nil,
        imageUrl: String? = nil,
        ogScrapeUrl: String? = nil,
        originalHeight: Int? = nil,
        originalWidth: Int? = nil,
        pretext: String? = nil,
        text: String? = nil,
        thumbUrl: String? = nil,
        title: String? = nil,
        titleLink: String? = nil,
        type: String? = nil
    ) {
        self.actions = actions
        self.assetUrl = assetUrl
        self.authorIcon = authorIcon
        self.authorLink = authorLink
        self.authorName = authorName
        self.color = color
        self.custom = custom
        self.duration = duration
        self.fallback = fallback
        self.fields = fields
        self.footer = footer
        self.footerIcon = footerIcon
        self.giphy = giphy
        self.imageUrl = imageUrl
        self.ogScrapeUrl = ogScrapeUrl
        self.originalHeight = originalHeight
        self.originalWidth = originalWidth
        self.pretext = pretext
        self.text = text
        self.thumbUrl = thumbUrl
        self.title = title
        self.titleLink = titleLink
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case actions
        case assetUrl = "asset_url"
        case authorIcon = "author_icon"
        case authorLink = "author_link"
        case authorName = "author_name"
        case color
        case custom
        case duration
        case fallback
        case fields
        case footer
        case footerIcon = "footer_icon"
        case giphy
        case imageUrl = "image_url"
        case ogScrapeUrl = "og_scrape_url"
        case originalHeight = "original_height"
        case originalWidth = "original_width"
        case pretext
        case text
        case thumbUrl = "thumb_url"
        case title
        case titleLink = "title_link"
        case type
    }
}
