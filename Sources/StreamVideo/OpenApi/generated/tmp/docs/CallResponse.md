# CallResponse

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**backstage** | **Bool** |  | 
**blockedUserIds** | **[String]** |  | 
**cid** | **String** | The unique identifier for a call (&lt;type&gt;:&lt;id&gt;) | 
**createdAt** | **Date** | Date/time of creation | 
**createdBy** | [**UserResponse**](UserResponse.md) |  | 
**currentSessionId** | **String** |  | 
**custom** | **[String: RawJSON]** | Custom data for this object | 
**egress** | [**EgressResponse**](EgressResponse.md) |  | 
**endedAt** | **Date** | Date/time when the call ended | [optional] 
**id** | **String** | Call ID | 
**ingress** | [**CallIngressResponse**](CallIngressResponse.md) |  | 
**joinAheadTimeSeconds** | **Int** |  | [optional] 
**recording** | **Bool** |  | 
**session** | [**CallSessionResponse**](CallSessionResponse.md) |  | [optional] 
**settings** | [**CallSettingsResponse**](CallSettingsResponse.md) |  | 
**startsAt** | **Date** | Date/time when the call will start | [optional] 
**team** | **String** |  | [optional] 
**thumbnails** | [**ThumbnailResponse**](ThumbnailResponse.md) |  | [optional] 
**transcribing** | **Bool** |  | 
**type** | **String** | The type of call | 
**updatedAt** | **Date** | Date/time of the last update | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


