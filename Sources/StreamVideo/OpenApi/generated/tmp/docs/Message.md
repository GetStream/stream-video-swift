# Message

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**attachments** | [Attachment] | Array of message attachments | 
**beforeMessageSendFailed** | **Bool** | Whether &#x60;before_message_send webhook&#x60; failed or not. Field is only accessible in push webhook | [optional] 
**cid** | **String** | Channel unique identifier in &lt;type&gt;:&lt;id&gt; format | 
**command** | **String** | Contains provided slash command | [optional] 
**createdAt** | **Date** | Date/time of creation | 
**custom** | **[String: RawJSON]** |  | 
**deletedAt** | **Date** | Date/time of deletion | [optional] 
**deletedReplyCount** | **Int** |  | 
**html** | **String** | Contains HTML markup of the message. Can only be set when using server-side API | 
**i18n** | **[String: String]** | Object with translations. Key &#x60;language&#x60; contains the original language key. Other keys contain translations | [optional] 
**id** | **String** | Message ID is unique string identifier of the message | 
**imageLabels** | [String: [String]] | Contains image moderation information | [optional] 
**latestReactions** | [Reaction] | List of 10 latest reactions to this message | 
**mentionedUsers** | [UserObject] | List of mentioned users | 
**messageTextUpdatedAt** | **Date** |  | [optional] 
**mml** | **String** | Should be empty if &#x60;text&#x60; is provided. Can only be set when using server-side API | [optional] 
**ownReactions** | [Reaction] | List of 10 latest reactions of authenticated user to this message | 
**parentId** | **String** | ID of parent message (thread) | [optional] 
**pinExpires** | **Date** | Date when pinned message expires | [optional] 
**pinned** | **Bool** | Whether message is pinned or not | 
**pinnedAt** | **Date** | Date when message got pinned | [optional] 
**pinnedBy** | [**UserObject**](UserObject.md) |  | [optional] 
**poll** | [**Poll**](Poll.md) |  | [optional] 
**pollId** | **String** | Identifier of the poll to include in the message | [optional] 
**quotedMessage** | [**Message**](Message.md) |  | [optional] 
**quotedMessageId** | **String** |  | [optional] 
**reactionCounts** | **[String: Int]** | An object containing number of reactions of each type. Key: reaction type (string), value: number of reactions (int) | 
**reactionGroups** | [String: ReactionGroupResponse] |  | 
**reactionScores** | **[String: Int]** | An object containing scores of reactions of each type. Key: reaction type (string), value: total score of reactions (int) | 
**replyCount** | **Int** | Number of replies to this message | 
**shadowed** | **Bool** | Whether the message was shadowed or not | 
**showInChannel** | **Bool** | Whether thread reply should be shown in the channel as well | [optional] 
**silent** | **Bool** | Whether message is silent or not | 
**text** | **String** | Text of the message. Should be empty if &#x60;mml&#x60; is provided | 
**threadParticipants** | [UserObject] | List of users who participate in thread | [optional] 
**type** | **String** | Contains type of the message | 
**updatedAt** | **Date** | Date/time of the last update | 
**user** | [**UserObject**](UserObject.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


