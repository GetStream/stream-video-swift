# ChannelResponse

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**autoTranslationEnabled** | **Bool** | Whether auto translation is enabled or not | [optional] 
**autoTranslationLanguage** | **String** | Language to translate to when auto translation is active | [optional] 
**cid** | **String** | Channel CID (&lt;type&gt;:&lt;id&gt;) | 
**config** | [**ChannelConfigWithInfo**](ChannelConfigWithInfo.md) |  | [optional] 
**cooldown** | **Int** | Cooldown period after sending each message | [optional] 
**createdAt** | **Date** | Date/time of creation | 
**createdBy** | [**UserObject**](UserObject.md) |  | [optional] 
**custom** | **[String: RawJSON]** |  | 
**deletedAt** | **Date** | Date/time of deletion | [optional] 
**disabled** | **Bool** |  | 
**frozen** | **Bool** | Whether channel is frozen or not | 
**hidden** | **Bool** | Whether this channel is hidden by current user or not | [optional] 
**hideMessagesBefore** | **Date** | Date since when the message history is accessible | [optional] 
**id** | **String** | Channel unique ID | 
**lastMessageAt** | **Date** | Date of the last message sent | [optional] 
**memberCount** | **Int** | Number of members in the channel | [optional] 
**members** | [ChannelMember] | List of channel members (max 100) | [optional] 
**muteExpiresAt** | **Date** | Date of mute expiration | [optional] 
**muted** | **Bool** | Whether this channel is muted or not | [optional] 
**ownCapabilities** | **[String]** | List of channel capabilities of authenticated user | [optional] 
**team** | **String** | Team the channel belongs to (multi-tenant only) | [optional] 
**truncatedAt** | **Date** | Date of the latest truncation of the channel | [optional] 
**truncatedBy** | [**UserObject**](UserObject.md) |  | [optional] 
**type** | **String** | Type of the channel | 
**updatedAt** | **Date** | Date/time of the last update | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


