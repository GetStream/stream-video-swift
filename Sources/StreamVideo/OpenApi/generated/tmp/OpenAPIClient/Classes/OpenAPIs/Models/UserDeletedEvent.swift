//
// UserDeletedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct UserDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSClientEvent {
    public var createdAt: Date
    public var deleteConversationChannels: Bool
    public var hardDelete: Bool
    public var markMessagesDeleted: Bool
    public var type: String = "user.deleted"
    public var user: UserObject?

    public init(createdAt: Date, deleteConversationChannels: Bool, hardDelete: Bool, markMessagesDeleted: Bool, type: String = "user.deleted", user: UserObject? = nil) {
        self.createdAt = createdAt
        self.deleteConversationChannels = deleteConversationChannels
        self.hardDelete = hardDelete
        self.markMessagesDeleted = markMessagesDeleted
        self.type = type
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case deleteConversationChannels = "delete_conversation_channels"
        case hardDelete = "hard_delete"
        case markMessagesDeleted = "mark_messages_deleted"
        case type
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(deleteConversationChannels, forKey: .deleteConversationChannels)
        try container.encode(hardDelete, forKey: .hardDelete)
        try container.encode(markMessagesDeleted, forKey: .markMessagesDeleted)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(user, forKey: .user)
    }
}

