//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UserDeletedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var createdAt: Date
    public var deleteConversationChannels: Bool
    public var hardDelete: Bool
    public var markMessagesDeleted: Bool
    public var type: String
    public var user: UserObject?

    public init(
        createdAt: Date,
        deleteConversationChannels: Bool,
        hardDelete: Bool,
        markMessagesDeleted: Bool,
        type: String,
        user: UserObject? = nil
    ) {
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
}
