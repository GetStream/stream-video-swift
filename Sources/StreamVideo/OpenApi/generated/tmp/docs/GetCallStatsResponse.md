# GetCallStatsResponse

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**aggregated** | [**AggregatedStats**](AggregatedStats.md) |  | [optional] 
**callDurationSeconds** | **Int** |  | 
**callStatus** | **String** |  | 
**callTimeline** | [**CallTimeline**](CallTimeline.md) |  | [optional] 
**duration** | **String** | Duration of the request in milliseconds | 
**jitter** | [**TimeStats**](TimeStats.md) |  | [optional] 
**latency** | [**TimeStats**](TimeStats.md) |  | [optional] 
**maxFreezesDurationSeconds** | **Int** |  | 
**maxParticipants** | **Int** |  | 
**maxTotalQualityLimitationDurationSeconds** | **Int** |  | 
**participantReport** | [UserStats] |  | 
**publishingParticipants** | **Int** |  | 
**qualityScore** | **Int** |  | 
**sfuCount** | **Int** |  | 
**sfus** | [SFULocationResponse] |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


