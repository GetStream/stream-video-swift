//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ChannelConfigWithInfo: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum Automod: String, Codable, CaseIterable {
        case ai = "AI"
        case disabled
        case simple
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public enum AutomodBehavior: String, Codable, CaseIterable {
        case block
        case flag
        case shadowBlock = "shadow_block"
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public var allowedFlagReasons: [String]? = nil
    public var automod: Automod
    public var automodBehavior: AutomodBehavior
    public var automodThresholds: Thresholds? = nil
    public var blocklist: String? = nil
    public var blocklistBehavior: String? = nil
    public var blocklists: [BlockListOptions]? = nil
    public var commands: [Command?]
    public var connectEvents: Bool
    public var createdAt: Date
    public var customEvents: Bool
    public var grants: [String: [String]]? = nil
    public var markMessagesPending: Bool
    public var maxMessageLength: Int
    public var mutes: Bool
    public var name: String
    public var partitionSize: Int? = nil
    public var partitionTtl: Int? = nil
    public var polls: Bool
    public var pushNotifications: Bool
    public var quotes: Bool
    public var reactions: Bool
    public var readEvents: Bool
    public var reminders: Bool
    public var replies: Bool
    public var search: Bool
    public var typingEvents: Bool
    public var updatedAt: Date
    public var uploads: Bool
    public var urlEnrichment: Bool

    public init(
        allowedFlagReasons: [String]? = nil,
        automod: Automod,
        automodBehavior: AutomodBehavior,
        automodThresholds: Thresholds? = nil,
        blocklist: String? = nil,
        blocklistBehavior: String? = nil,
        blocklists: [BlockListOptions]? = nil,
        commands: [Command?],
        connectEvents: Bool,
        createdAt: Date,
        customEvents: Bool,
        grants: [String: [String]]? = nil,
        markMessagesPending: Bool,
        maxMessageLength: Int,
        mutes: Bool,
        name: String,
        partitionSize: Int? = nil,
        partitionTtl: Int? = nil,
        polls: Bool,
        pushNotifications: Bool,
        quotes: Bool,
        reactions: Bool,
        readEvents: Bool,
        reminders: Bool,
        replies: Bool,
        search: Bool,
        typingEvents: Bool,
        updatedAt: Date,
        uploads: Bool,
        urlEnrichment: Bool
    ) {
        self.allowedFlagReasons = allowedFlagReasons
        self.automod = automod
        self.automodBehavior = automodBehavior
        self.automodThresholds = automodThresholds
        self.blocklist = blocklist
        self.blocklistBehavior = blocklistBehavior
        self.blocklists = blocklists
        self.commands = commands
        self.connectEvents = connectEvents
        self.createdAt = createdAt
        self.customEvents = customEvents
        self.grants = grants
        self.markMessagesPending = markMessagesPending
        self.maxMessageLength = maxMessageLength
        self.mutes = mutes
        self.name = name
        self.partitionSize = partitionSize
        self.partitionTtl = partitionTtl
        self.polls = polls
        self.pushNotifications = pushNotifications
        self.quotes = quotes
        self.reactions = reactions
        self.readEvents = readEvents
        self.reminders = reminders
        self.replies = replies
        self.search = search
        self.typingEvents = typingEvents
        self.updatedAt = updatedAt
        self.uploads = uploads
        self.urlEnrichment = urlEnrichment
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case allowedFlagReasons = "allowed_flag_reasons"
        case automod
        case automodBehavior = "automod_behavior"
        case automodThresholds = "automod_thresholds"
        case blocklist
        case blocklistBehavior = "blocklist_behavior"
        case blocklists
        case commands
        case connectEvents = "connect_events"
        case createdAt = "created_at"
        case customEvents = "custom_events"
        case grants
        case markMessagesPending = "mark_messages_pending"
        case maxMessageLength = "max_message_length"
        case mutes
        case name
        case partitionSize = "partition_size"
        case partitionTtl = "partition_ttl"
        case polls
        case pushNotifications = "push_notifications"
        case quotes
        case reactions
        case readEvents = "read_events"
        case reminders
        case replies
        case search
        case typingEvents = "typing_events"
        case updatedAt = "updated_at"
        case uploads
        case urlEnrichment = "url_enrichment"
    }
}
