//
// Attachment.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct Attachment: Codable, JSONEncodable, Hashable {
    public var actions: [Action]?
    public var assetUrl: String?
    public var authorIcon: String?
    public var authorLink: String?
    public var authorName: String?
    public var color: String?
    public var custom: [String: RawJSON]
    public var fallback: String?
    public var fields: [Field]?
    public var footer: String?
    public var footerIcon: String?
    public var giphy: Images?
    public var imageUrl: String?
    public var ogScrapeUrl: String?
    public var originalHeight: Int?
    public var originalWidth: Int?
    public var pretext: String?
    public var text: String?
    public var thumbUrl: String?
    public var title: String?
    public var titleLink: String?
    /** Attachment type (e.g. image, video, url) */
    public var type: String?

    public init(actions: [Action]? = nil, assetUrl: String? = nil, authorIcon: String? = nil, authorLink: String? = nil, authorName: String? = nil, color: String? = nil, custom: [String: RawJSON], fallback: String? = nil, fields: [Field]? = nil, footer: String? = nil, footerIcon: String? = nil, giphy: Images? = nil, imageUrl: String? = nil, ogScrapeUrl: String? = nil, originalHeight: Int? = nil, originalWidth: Int? = nil, pretext: String? = nil, text: String? = nil, thumbUrl: String? = nil, title: String? = nil, titleLink: String? = nil, type: String? = nil) {
        self.actions = actions
        self.assetUrl = assetUrl
        self.authorIcon = authorIcon
        self.authorLink = authorLink
        self.authorName = authorName
        self.color = color
        self.custom = custom
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(actions, forKey: .actions)
        try container.encodeIfPresent(assetUrl, forKey: .assetUrl)
        try container.encodeIfPresent(authorIcon, forKey: .authorIcon)
        try container.encodeIfPresent(authorLink, forKey: .authorLink)
        try container.encodeIfPresent(authorName, forKey: .authorName)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(custom, forKey: .custom)
        try container.encodeIfPresent(fallback, forKey: .fallback)
        try container.encodeIfPresent(fields, forKey: .fields)
        try container.encodeIfPresent(footer, forKey: .footer)
        try container.encodeIfPresent(footerIcon, forKey: .footerIcon)
        try container.encodeIfPresent(giphy, forKey: .giphy)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(ogScrapeUrl, forKey: .ogScrapeUrl)
        try container.encodeIfPresent(originalHeight, forKey: .originalHeight)
        try container.encodeIfPresent(originalWidth, forKey: .originalWidth)
        try container.encodeIfPresent(pretext, forKey: .pretext)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(thumbUrl, forKey: .thumbUrl)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(titleLink, forKey: .titleLink)
        try container.encodeIfPresent(type, forKey: .type)
    }
}

