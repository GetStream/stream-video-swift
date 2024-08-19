# WSEvent

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**blockedByUser** | [**UserResponse**](UserResponse.md) |  | [optional] 
**callCid** | **String** |  | 
**createdAt** | **Date** |  | 
**type** | **String** |  | [default to "user.unbanned"]
**user** | [**UserObject**](UserObject.md) |  | 
**call** | [**CallResponse**](CallResponse.md) |  | 
**members** | [MemberResponse] | Call members | 
**hlsPlaylistUrl** | **String** |  | 
**capabilitiesByRole** | [String: [String]] | The capabilities by role for this call | 
**notifyUser** | **Bool** |  | 
**sessionId** | **String** | Call session ID | 
**reaction** | [**ReactionResponse**](ReactionResponse.md) |  | 
**callRecording** | [**CallRecording**](CallRecording.md) |  | 
**reason** | **String** |  | [optional] 
**video** | **Bool** |  | 
**name** | **String** |  | 
**participant** | [**CallParticipantResponse**](CallParticipantResponse.md) |  | 
**callTranscription** | [**CallTranscription**](CallTranscription.md) |  | 
**fromUserId** | **String** |  | 
**mutedUserIds** | **[String]** |  | 
**closedCaption** | [**CallClosedCaption**](CallClosedCaption.md) |  | 
**connectionId** | **String** |  | 
**me** | [**OwnUser**](OwnUser.md) |  | 
**error** | [**APIError**](APIError.md) |  | 
**custom** | **[String: RawJSON]** | Custom data for this object | 
**cid** | **String** |  | 
**item** | [**ReviewQueueItem**](ReviewQueueItem.md) |  | [optional] 
**message** | [**Message**](Message.md) |  | [optional] 
**objectId** | **String** |  | [optional] 
**permissions** | **[String]** | The list of permissions requested by the user | 
**ownCapabilities** | [OwnCapability] | The capabilities of the current user | 
**channelId** | **String** |  | 
**channelType** | **String** |  | 
**createdBy** | [**UserObject**](UserObject.md) |  | 
**expiration** | **Date** |  | [optional] 
**shadow** | **Bool** |  | 
**team** | **String** |  | [optional] 
**deleteConversationChannels** | **Bool** |  | 
**hardDelete** | **Bool** |  | 
**markMessagesDeleted** | **Bool** |  | 
**targetUser** | **String** |  | [optional] 
**targetUsers** | **[String]** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


