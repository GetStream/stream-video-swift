# UserSessionStats

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**browser** | **String** |  | [optional] 
**browserVersion** | **String** |  | [optional] 
**currentIp** | **String** |  | [optional] 
**currentSfu** | **String** |  | [optional] 
**deviceModel** | **String** |  | [optional] 
**deviceVersion** | **String** |  | [optional] 
**distanceToSfuKilometers** | **Float** |  | [optional] 
**freezeDurationSeconds** | **Int** |  | 
**geolocation** | [**GeolocationResult**](GeolocationResult.md) |  | [optional] 
**jitter** | [**Stats**](Stats.md) |  | [optional] 
**latency** | [**Stats**](Stats.md) |  | [optional] 
**maxFirPerSecond** | **Float** |  | [optional] 
**maxFreezeFraction** | **Float** |  | 
**maxFreezesDurationSeconds** | **Int** |  | 
**maxFreezesPerSecond** | **Float** |  | [optional] 
**maxNackPerSecond** | **Float** |  | [optional] 
**maxPliPerSecond** | **Float** |  | [optional] 
**maxPublishingVideoQuality** | [**VideoQuality**](VideoQuality.md) |  | [optional] 
**maxReceivingVideoQuality** | [**VideoQuality**](VideoQuality.md) |  | [optional] 
**os** | **String** |  | [optional] 
**osVersion** | **String** |  | [optional] 
**packetLossFraction** | **Float** |  | 
**pubSubHints** | [**MediaPubSubHint**](MediaPubSubHint.md) |  | [optional] 
**publishedTracks** | [PublishedTrackInfo] |  | [optional] 
**publisherAudioMos** | [**MOSStats**](MOSStats.md) |  | [optional] 
**publisherJitter** | [**Stats**](Stats.md) |  | [optional] 
**publisherLatency** | [**Stats**](Stats.md) |  | [optional] 
**publisherNoiseCancellationSeconds** | **Float** |  | [optional] 
**publisherPacketLossFraction** | **Float** |  | 
**publisherQualityLimitationFraction** | **Float** |  | [optional] 
**publisherVideoQualityLimitationDurationSeconds** | **[String: Float]** |  | [optional] 
**publishingAudioCodec** | **String** |  | [optional] 
**publishingDurationSeconds** | **Int** |  | 
**publishingVideoCodec** | **String** |  | [optional] 
**qualityScore** | **Float** |  | 
**receivingAudioCodec** | **String** |  | [optional] 
**receivingDurationSeconds** | **Int** |  | 
**receivingVideoCodec** | **String** |  | [optional] 
**sdk** | **String** |  | [optional] 
**sdkVersion** | **String** |  | [optional] 
**sessionId** | **String** |  | 
**subscriberAudioMos** | [**MOSStats**](MOSStats.md) |  | [optional] 
**subscriberJitter** | [**Stats**](Stats.md) |  | [optional] 
**subscriberLatency** | [**Stats**](Stats.md) |  | [optional] 
**subscriberVideoQualityThrottledDurationSeconds** | **Float** |  | [optional] 
**subsessions** | [Subsession] |  | [optional] 
**timeline** | [**CallTimeline**](CallTimeline.md) |  | [optional] 
**totalPixelsIn** | **Int** |  | 
**totalPixelsOut** | **Int** |  | 
**webrtcVersion** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


