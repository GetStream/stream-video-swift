# ProductvideoAPI

All URIs are relative to *https://stream-io-api.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptCall**](ProductvideoAPI.md#acceptcall) | **POST** /video/call/{type}/{id}/accept | Accept Call
[**blockUser**](ProductvideoAPI.md#blockuser) | **POST** /video/call/{type}/{id}/block | Block user on a call
[**collectUserFeedback**](ProductvideoAPI.md#collectuserfeedback) | **POST** /video/call/{type}/{id}/feedback/{session} | Collect user feedback
[**createDevice**](ProductvideoAPI.md#createdevice) | **POST** /video/devices | Create device
[**createGuest**](ProductvideoAPI.md#createguest) | **POST** /video/guest | Create Guest
[**deleteCall**](ProductvideoAPI.md#deletecall) | **POST** /video/call/{type}/{id}/delete | Delete Call
[**deleteDevice**](ProductvideoAPI.md#deletedevice) | **DELETE** /video/devices | Delete device
[**deleteRecording**](ProductvideoAPI.md#deleterecording) | **DELETE** /video/call/{type}/{id}/{session}/recordings/{filename} | Delete recording
[**deleteTranscription**](ProductvideoAPI.md#deletetranscription) | **DELETE** /video/call/{type}/{id}/{session}/transcriptions/{filename} | Delete transcription
[**endCall**](ProductvideoAPI.md#endcall) | **POST** /video/call/{type}/{id}/mark_ended | End call
[**getCall**](ProductvideoAPI.md#getcall) | **GET** /video/call/{type}/{id} | Get Call
[**getCallStats**](ProductvideoAPI.md#getcallstats) | **GET** /video/call/{type}/{id}/stats/{session} | Get Call Stats
[**getEdges**](ProductvideoAPI.md#getedges) | **GET** /video/edges | Get Edges
[**getOrCreateCall**](ProductvideoAPI.md#getorcreatecall) | **POST** /video/call/{type}/{id} | Get or create a call
[**goLive**](ProductvideoAPI.md#golive) | **POST** /video/call/{type}/{id}/go_live | Set call as live
[**joinCall**](ProductvideoAPI.md#joincall) | **POST** /video/call/{type}/{id}/join | Join call
[**listDevices**](ProductvideoAPI.md#listdevices) | **GET** /video/devices | List devices
[**listRecordings**](ProductvideoAPI.md#listrecordings) | **GET** /video/call/{type}/{id}/recordings | List recordings
[**listTranscriptions**](ProductvideoAPI.md#listtranscriptions) | **GET** /video/call/{type}/{id}/transcriptions | List transcriptions
[**muteUsers**](ProductvideoAPI.md#muteusers) | **POST** /video/call/{type}/{id}/mute_users | Mute users
[**queryCallMembers**](ProductvideoAPI.md#querycallmembers) | **POST** /video/call/members | Query call members
[**queryCallStats**](ProductvideoAPI.md#querycallstats) | **POST** /video/call/stats | Query Call Stats
[**queryCalls**](ProductvideoAPI.md#querycalls) | **POST** /video/calls | Query call
[**rejectCall**](ProductvideoAPI.md#rejectcall) | **POST** /video/call/{type}/{id}/reject | Reject Call
[**requestPermission**](ProductvideoAPI.md#requestpermission) | **POST** /video/call/{type}/{id}/request_permission | Request permission
[**sendCallEvent**](ProductvideoAPI.md#sendcallevent) | **POST** /video/call/{type}/{id}/event | Send custom event
[**sendVideoReaction**](ProductvideoAPI.md#sendvideoreaction) | **POST** /video/call/{type}/{id}/reaction | Send reaction to the call
[**startHLSBroadcasting**](ProductvideoAPI.md#starthlsbroadcasting) | **POST** /video/call/{type}/{id}/start_broadcasting | Start HLS broadcasting
[**startRTMPBroadcast**](ProductvideoAPI.md#startrtmpbroadcast) | **POST** /video/call/{type}/{id}/rtmp_broadcasts | Start RTMP broadcasts
[**startRecording**](ProductvideoAPI.md#startrecording) | **POST** /video/call/{type}/{id}/start_recording | Start recording
[**startTranscription**](ProductvideoAPI.md#starttranscription) | **POST** /video/call/{type}/{id}/start_transcription | Start transcription
[**stopAllRTMPBroadcasts**](ProductvideoAPI.md#stopallrtmpbroadcasts) | **POST** /video/call/{type}/{id}/rtmp_broadcasts/stop | Stop all RTMP broadcasts for a call
[**stopHLSBroadcasting**](ProductvideoAPI.md#stophlsbroadcasting) | **POST** /video/call/{type}/{id}/stop_broadcasting | Stop HLS broadcasting
[**stopLive**](ProductvideoAPI.md#stoplive) | **POST** /video/call/{type}/{id}/stop_live | Set call as not live
[**stopRTMPBroadcast**](ProductvideoAPI.md#stoprtmpbroadcast) | **POST** /video/call/{type}/{id}/rtmp_broadcasts/{name}/stop | Stop RTMP broadcasts
[**stopRecording**](ProductvideoAPI.md#stoprecording) | **POST** /video/call/{type}/{id}/stop_recording | Stop recording
[**stopTranscription**](ProductvideoAPI.md#stoptranscription) | **POST** /video/call/{type}/{id}/stop_transcription | Stop transcription
[**unblockUser**](ProductvideoAPI.md#unblockuser) | **POST** /video/call/{type}/{id}/unblock | Unblocks user on a call
[**updateCall**](ProductvideoAPI.md#updatecall) | **PATCH** /video/call/{type}/{id} | Update Call
[**updateCallMembers**](ProductvideoAPI.md#updatecallmembers) | **POST** /video/call/{type}/{id}/members | Update Call Member
[**updateUserPermissions**](ProductvideoAPI.md#updateuserpermissions) | **POST** /video/call/{type}/{id}/user_permissions | Update user permissions
[**videoConnect**](ProductvideoAPI.md#videoconnect) | **GET** /video/longpoll | Video Connect (WebSocket)
[**videoPin**](ProductvideoAPI.md#videopin) | **POST** /video/call/{type}/{id}/pin | Pin
[**videoUnpin**](ProductvideoAPI.md#videounpin) | **POST** /video/call/{type}/{id}/unpin | Unpin


# **acceptCall**
```swift
    open class func acceptCall(type: String, id: String, completion: @escaping (_ data: AcceptCallResponse?, _ error: Error?) -> Void)
```

Accept Call

  Sends events: - call.accepted  Required permissions: - JoinCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Accept Call
ProductvideoAPI.acceptCall(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**AcceptCallResponse**](AcceptCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **blockUser**
```swift
    open class func blockUser(type: String, id: String, blockUserRequest: BlockUserRequest, completion: @escaping (_ data: BlockUserResponse?, _ error: Error?) -> Void)
```

Block user on a call

Block a user, preventing them from joining the call until they are unblocked.  Sends events: - call.blocked_user  Required permissions: - BlockUser 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let blockUserRequest = BlockUserRequest(userId: "userId_example") // BlockUserRequest | 

// Block user on a call
ProductvideoAPI.blockUser(type: type, id: id, blockUserRequest: blockUserRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **blockUserRequest** | [**BlockUserRequest**](BlockUserRequest.md) |  | 

### Return type

[**BlockUserResponse**](BlockUserResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **collectUserFeedback**
```swift
    open class func collectUserFeedback(type: String, id: String, session: String, collectUserFeedbackRequest: CollectUserFeedbackRequest, completion: @escaping (_ data: CollectUserFeedbackResponse?, _ error: Error?) -> Void)
```

Collect user feedback

  Required permissions: - JoinCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let session = "session_example" // String | 
let collectUserFeedbackRequest = CollectUserFeedbackRequest(custom: "TODO", rating: 123, reason: "reason_example", sdk: "sdk_example", sdkVersion: "sdkVersion_example", userSessionId: "userSessionId_example") // CollectUserFeedbackRequest | 

// Collect user feedback
ProductvideoAPI.collectUserFeedback(type: type, id: id, session: session, collectUserFeedbackRequest: collectUserFeedbackRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **session** | **String** |  | 
 **collectUserFeedbackRequest** | [**CollectUserFeedbackRequest**](CollectUserFeedbackRequest.md) |  | 

### Return type

[**CollectUserFeedbackResponse**](CollectUserFeedbackResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createDevice**
```swift
    open class func createDevice(createDeviceRequest: CreateDeviceRequest, completion: @escaping (_ data: ModelResponse?, _ error: Error?) -> Void)
```

Create device

Adds a new device to a user, if the same device already exists the call will have no effect 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let createDeviceRequest = CreateDeviceRequest(id: "id_example", pushProvider: "pushProvider_example", pushProviderName: "pushProviderName_example", voipToken: false) // CreateDeviceRequest | 

// Create device
ProductvideoAPI.createDevice(createDeviceRequest: createDeviceRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createDeviceRequest** | [**CreateDeviceRequest**](CreateDeviceRequest.md) |  | 

### Return type

[**ModelResponse**](ModelResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createGuest**
```swift
    open class func createGuest(createGuestRequest: CreateGuestRequest, completion: @escaping (_ data: CreateGuestResponse?, _ error: Error?) -> Void)
```

Create Guest

 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let createGuestRequest = CreateGuestRequest(user: UserRequest(custom: "TODO", id: "id_example", image: "image_example", invisible: false, language: "language_example", name: "name_example", privacySettings: PrivacySettings(readReceipts: ReadReceipts(enabled: false), typingIndicators: TypingIndicators(enabled: false)), pushNotifications: PushNotificationSettingsInput(disabled: NullBool(hasValue: false, value: false), disabledUntil: NullTime(hasValue: false, value: Date())))) // CreateGuestRequest | 

// Create Guest
ProductvideoAPI.createGuest(createGuestRequest: createGuestRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGuestRequest** | [**CreateGuestRequest**](CreateGuestRequest.md) |  | 

### Return type

[**CreateGuestResponse**](CreateGuestResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteCall**
```swift
    open class func deleteCall(type: String, id: String, deleteCallRequest: DeleteCallRequest, completion: @escaping (_ data: DeleteCallResponse?, _ error: Error?) -> Void)
```

Delete Call

  Sends events: - call.deleted  Required permissions: - DeleteCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let deleteCallRequest = DeleteCallRequest(hard: false) // DeleteCallRequest | 

// Delete Call
ProductvideoAPI.deleteCall(type: type, id: id, deleteCallRequest: deleteCallRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **deleteCallRequest** | [**DeleteCallRequest**](DeleteCallRequest.md) |  | 

### Return type

[**DeleteCallResponse**](DeleteCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDevice**
```swift
    open class func deleteDevice(id: String, completion: @escaping (_ data: ModelResponse?, _ error: Error?) -> Void)
```

Delete device

Deletes one device 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | 

// Delete device
ProductvideoAPI.deleteDevice(id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String** |  | 

### Return type

[**ModelResponse**](ModelResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteRecording**
```swift
    open class func deleteRecording(type: String, id: String, session: String, filename: String, completion: @escaping (_ data: DeleteRecordingResponse?, _ error: Error?) -> Void)
```

Delete recording

Deletes recording  Required permissions: - DeleteRecording 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let session = "session_example" // String | 
let filename = "filename_example" // String | 

// Delete recording
ProductvideoAPI.deleteRecording(type: type, id: id, session: session, filename: filename) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **session** | **String** |  | 
 **filename** | **String** |  | 

### Return type

[**DeleteRecordingResponse**](DeleteRecordingResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteTranscription**
```swift
    open class func deleteTranscription(type: String, id: String, session: String, filename: String, completion: @escaping (_ data: DeleteTranscriptionResponse?, _ error: Error?) -> Void)
```

Delete transcription

Deletes transcription  Required permissions: - DeleteTranscription 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let session = "session_example" // String | 
let filename = "filename_example" // String | 

// Delete transcription
ProductvideoAPI.deleteTranscription(type: type, id: id, session: session, filename: filename) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **session** | **String** |  | 
 **filename** | **String** |  | 

### Return type

[**DeleteTranscriptionResponse**](DeleteTranscriptionResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **endCall**
```swift
    open class func endCall(type: String, id: String, completion: @escaping (_ data: EndCallResponse?, _ error: Error?) -> Void)
```

End call

  Sends events: - call.ended  Required permissions: - EndCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// End call
ProductvideoAPI.endCall(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**EndCallResponse**](EndCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCall**
```swift
    open class func getCall(type: String, id: String, connectionId: String? = nil, membersLimit: Int? = nil, ring: Bool? = nil, notify: Bool? = nil, video: Bool? = nil, completion: @escaping (_ data: GetCallResponse?, _ error: Error?) -> Void)
```

Get Call

  Required permissions: - ReadCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let connectionId = "connectionId_example" // String |  (optional)
let membersLimit = 987 // Int |  (optional)
let ring = true // Bool |  (optional)
let notify = true // Bool |  (optional)
let video = true // Bool |  (optional)

// Get Call
ProductvideoAPI.getCall(type: type, id: id, connectionId: connectionId, membersLimit: membersLimit, ring: ring, notify: notify, video: video) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **connectionId** | **String** |  | [optional] 
 **membersLimit** | **Int** |  | [optional] 
 **ring** | **Bool** |  | [optional] 
 **notify** | **Bool** |  | [optional] 
 **video** | **Bool** |  | [optional] 

### Return type

[**GetCallResponse**](GetCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCallStats**
```swift
    open class func getCallStats(type: String, id: String, session: String, completion: @escaping (_ data: GetCallStatsResponse?, _ error: Error?) -> Void)
```

Get Call Stats

  Required permissions: - ReadCallStats 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let session = "session_example" // String | 

// Get Call Stats
ProductvideoAPI.getCallStats(type: type, id: id, session: session) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **session** | **String** |  | 

### Return type

[**GetCallStatsResponse**](GetCallStatsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getEdges**
```swift
    open class func getEdges(completion: @escaping (_ data: GetEdgesResponse?, _ error: Error?) -> Void)
```

Get Edges

Returns the list of all edges available for video calls. 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Get Edges
ProductvideoAPI.getEdges() { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GetEdgesResponse**](GetEdgesResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrCreateCall**
```swift
    open class func getOrCreateCall(type: String, id: String, getOrCreateCallRequest: GetOrCreateCallRequest, connectionId: String? = nil, completion: @escaping (_ data: GetOrCreateCallResponse?, _ error: Error?) -> Void)
```

Get or create a call

Gets or creates a new call  Sends events: - call.created - call.notification - call.ring  Required permissions: - CreateCall - ReadCall - UpdateCallSettings 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let getOrCreateCallRequest = GetOrCreateCallRequest(data: CallRequest(custom: "TODO", members: [MemberRequest(custom: "TODO", role: "role_example", userId: "userId_example")], settingsOverride: CallSettingsRequest(audio: AudioSettingsRequest(accessRequestEnabled: false, defaultDevice: "defaultDevice_example", micDefaultOn: false, noiseCancellation: NoiseCancellationSettings(mode: "mode_example"), opusDtxEnabled: false, redundantCodingEnabled: false, speakerDefaultOn: false), backstage: BackstageSettingsRequest(enabled: false, joinAheadTimeSeconds: 123), broadcasting: BroadcastSettingsRequest(enabled: false, hls: HLSSettingsRequest(autoOn: false, enabled: false, qualityTracks: ["qualityTracks_example"]), rtmp: RTMPSettingsRequest(enabled: false, maxDurationMinutes: 123, quality: "quality_example")), geofencing: GeofenceSettingsRequest(names: ["names_example"]), limits: LimitsSettingsRequest(maxDurationSeconds: 123, maxParticipants: 123), recording: RecordSettingsRequest(audioOnly: false, mode: "mode_example", quality: "quality_example"), ring: RingSettingsRequest(autoCancelTimeoutMs: 123, incomingCallTimeoutMs: 123, missedCallTimeoutMs: 123), screensharing: ScreensharingSettingsRequest(accessRequestEnabled: false, enabled: false, targetResolution: TargetResolution(bitrate: 123, height: 123, width: 123)), thumbnails: ThumbnailsSettingsRequest(enabled: false), transcription: TranscriptionSettingsRequest(closedCaptionMode: "closedCaptionMode_example", languages: ["languages_example"], mode: "mode_example"), video: VideoSettingsRequest(accessRequestEnabled: false, cameraDefaultOn: false, cameraFacing: "cameraFacing_example", enabled: false, targetResolution: nil)), startsAt: Date(), team: "team_example", video: false), membersLimit: 123, notify: false, ring: false, video: false) // GetOrCreateCallRequest | 
let connectionId = "connectionId_example" // String |  (optional)

// Get or create a call
ProductvideoAPI.getOrCreateCall(type: type, id: id, getOrCreateCallRequest: getOrCreateCallRequest, connectionId: connectionId) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **getOrCreateCallRequest** | [**GetOrCreateCallRequest**](GetOrCreateCallRequest.md) |  | 
 **connectionId** | **String** |  | [optional] 

### Return type

[**GetOrCreateCallResponse**](GetOrCreateCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **goLive**
```swift
    open class func goLive(type: String, id: String, goLiveRequest: GoLiveRequest, completion: @escaping (_ data: GoLiveResponse?, _ error: Error?) -> Void)
```

Set call as live

  Sends events: - call.live_started  Required permissions: - UpdateCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let goLiveRequest = GoLiveRequest(recordingStorageName: "recordingStorageName_example", startHls: false, startRecording: false, startRtmpBroadcasts: false, startTranscription: false, transcriptionStorageName: "transcriptionStorageName_example") // GoLiveRequest | 

// Set call as live
ProductvideoAPI.goLive(type: type, id: id, goLiveRequest: goLiveRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **goLiveRequest** | [**GoLiveRequest**](GoLiveRequest.md) |  | 

### Return type

[**GoLiveResponse**](GoLiveResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **joinCall**
```swift
    open class func joinCall(type: String, id: String, joinCallRequest: JoinCallRequest, connectionId: String? = nil, completion: @escaping (_ data: JoinCallResponse?, _ error: Error?) -> Void)
```

Join call

Request to join a call  Required permissions: - CreateCall - JoinCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let joinCallRequest = JoinCallRequest(create: false, data: CallRequest(custom: "TODO", members: [MemberRequest(custom: "TODO", role: "role_example", userId: "userId_example")], settingsOverride: CallSettingsRequest(audio: AudioSettingsRequest(accessRequestEnabled: false, defaultDevice: "defaultDevice_example", micDefaultOn: false, noiseCancellation: NoiseCancellationSettings(mode: "mode_example"), opusDtxEnabled: false, redundantCodingEnabled: false, speakerDefaultOn: false), backstage: BackstageSettingsRequest(enabled: false, joinAheadTimeSeconds: 123), broadcasting: BroadcastSettingsRequest(enabled: false, hls: HLSSettingsRequest(autoOn: false, enabled: false, qualityTracks: ["qualityTracks_example"]), rtmp: RTMPSettingsRequest(enabled: false, maxDurationMinutes: 123, quality: "quality_example")), geofencing: GeofenceSettingsRequest(names: ["names_example"]), limits: LimitsSettingsRequest(maxDurationSeconds: 123, maxParticipants: 123), recording: RecordSettingsRequest(audioOnly: false, mode: "mode_example", quality: "quality_example"), ring: RingSettingsRequest(autoCancelTimeoutMs: 123, incomingCallTimeoutMs: 123, missedCallTimeoutMs: 123), screensharing: ScreensharingSettingsRequest(accessRequestEnabled: false, enabled: false, targetResolution: TargetResolution(bitrate: 123, height: 123, width: 123)), thumbnails: ThumbnailsSettingsRequest(enabled: false), transcription: TranscriptionSettingsRequest(closedCaptionMode: "closedCaptionMode_example", languages: ["languages_example"], mode: "mode_example"), video: VideoSettingsRequest(accessRequestEnabled: false, cameraDefaultOn: false, cameraFacing: "cameraFacing_example", enabled: false, targetResolution: nil)), startsAt: Date(), team: "team_example", video: false), location: "location_example", membersLimit: 123, migratingFrom: "migratingFrom_example", notify: false, ring: false, video: false) // JoinCallRequest | 
let connectionId = "connectionId_example" // String |  (optional)

// Join call
ProductvideoAPI.joinCall(type: type, id: id, joinCallRequest: joinCallRequest, connectionId: connectionId) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **joinCallRequest** | [**JoinCallRequest**](JoinCallRequest.md) |  | 
 **connectionId** | **String** |  | [optional] 

### Return type

[**JoinCallResponse**](JoinCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listDevices**
```swift
    open class func listDevices(completion: @escaping (_ data: ListDevicesResponse?, _ error: Error?) -> Void)
```

List devices

Returns all available devices 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// List devices
ProductvideoAPI.listDevices() { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ListDevicesResponse**](ListDevicesResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listRecordings**
```swift
    open class func listRecordings(type: String, id: String, completion: @escaping (_ data: ListRecordingsResponse?, _ error: Error?) -> Void)
```

List recordings

Lists recordings  Required permissions: - ListRecordings 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// List recordings
ProductvideoAPI.listRecordings(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**ListRecordingsResponse**](ListRecordingsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTranscriptions**
```swift
    open class func listTranscriptions(type: String, id: String, completion: @escaping (_ data: ListTranscriptionsResponse?, _ error: Error?) -> Void)
```

List transcriptions

Lists transcriptions  Required permissions: - ListTranscriptions 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// List transcriptions
ProductvideoAPI.listTranscriptions(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**ListTranscriptionsResponse**](ListTranscriptionsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **muteUsers**
```swift
    open class func muteUsers(type: String, id: String, muteUsersRequest: MuteUsersRequest, completion: @escaping (_ data: MuteUsersResponse?, _ error: Error?) -> Void)
```

Mute users

Mutes users in a call  Required permissions: - MuteUsers 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let muteUsersRequest = MuteUsersRequest(audio: false, muteAllUsers: false, screenshare: false, screenshareAudio: false, userIds: ["userIds_example"], video: false) // MuteUsersRequest | 

// Mute users
ProductvideoAPI.muteUsers(type: type, id: id, muteUsersRequest: muteUsersRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **muteUsersRequest** | [**MuteUsersRequest**](MuteUsersRequest.md) |  | 

### Return type

[**MuteUsersResponse**](MuteUsersResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **queryCallMembers**
```swift
    open class func queryCallMembers(queryCallMembersRequest: QueryCallMembersRequest, completion: @escaping (_ data: QueryCallMembersResponse?, _ error: Error?) -> Void)
```

Query call members

Query call members with filter query  Required permissions: - ReadCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let queryCallMembersRequest = QueryCallMembersRequest(filterConditions: "TODO", id: "id_example", limit: 123, next: "next_example", prev: "prev_example", sort: [SortParamRequest(direction: 123, field: "field_example")], type: "type_example") // QueryCallMembersRequest | 

// Query call members
ProductvideoAPI.queryCallMembers(queryCallMembersRequest: queryCallMembersRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **queryCallMembersRequest** | [**QueryCallMembersRequest**](QueryCallMembersRequest.md) |  | 

### Return type

[**QueryCallMembersResponse**](QueryCallMembersResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **queryCallStats**
```swift
    open class func queryCallStats(queryCallStatsRequest: QueryCallStatsRequest, completion: @escaping (_ data: QueryCallStatsResponse?, _ error: Error?) -> Void)
```

Query Call Stats

  Required permissions: - ReadCallStats 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let queryCallStatsRequest = QueryCallStatsRequest(filterConditions: "TODO", limit: 123, next: "next_example", prev: "prev_example", sort: [SortParamRequest(direction: 123, field: "field_example")]) // QueryCallStatsRequest | 

// Query Call Stats
ProductvideoAPI.queryCallStats(queryCallStatsRequest: queryCallStatsRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **queryCallStatsRequest** | [**QueryCallStatsRequest**](QueryCallStatsRequest.md) |  | 

### Return type

[**QueryCallStatsResponse**](QueryCallStatsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **queryCalls**
```swift
    open class func queryCalls(queryCallsRequest: QueryCallsRequest, connectionId: String? = nil, completion: @escaping (_ data: QueryCallsResponse?, _ error: Error?) -> Void)
```

Query call

Query calls with filter query  Required permissions: - ReadCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let queryCallsRequest = QueryCallsRequest(filterConditions: "TODO", limit: 123, next: "next_example", prev: "prev_example", sort: [SortParamRequest(direction: 123, field: "field_example")], watch: false) // QueryCallsRequest | 
let connectionId = "connectionId_example" // String |  (optional)

// Query call
ProductvideoAPI.queryCalls(queryCallsRequest: queryCallsRequest, connectionId: connectionId) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **queryCallsRequest** | [**QueryCallsRequest**](QueryCallsRequest.md) |  | 
 **connectionId** | **String** |  | [optional] 

### Return type

[**QueryCallsResponse**](QueryCallsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectCall**
```swift
    open class func rejectCall(type: String, id: String, rejectCallRequest: RejectCallRequest, completion: @escaping (_ data: RejectCallResponse?, _ error: Error?) -> Void)
```

Reject Call

  Sends events: - call.rejected  Required permissions: - JoinCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let rejectCallRequest = RejectCallRequest(reason: "reason_example") // RejectCallRequest | 

// Reject Call
ProductvideoAPI.rejectCall(type: type, id: id, rejectCallRequest: rejectCallRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **rejectCallRequest** | [**RejectCallRequest**](RejectCallRequest.md) |  | 

### Return type

[**RejectCallResponse**](RejectCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestPermission**
```swift
    open class func requestPermission(type: String, id: String, requestPermissionRequest: RequestPermissionRequest, completion: @escaping (_ data: RequestPermissionResponse?, _ error: Error?) -> Void)
```

Request permission

Request permission to perform an action  Sends events: - call.permission_request 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let requestPermissionRequest = RequestPermissionRequest(permissions: ["permissions_example"]) // RequestPermissionRequest | 

// Request permission
ProductvideoAPI.requestPermission(type: type, id: id, requestPermissionRequest: requestPermissionRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **requestPermissionRequest** | [**RequestPermissionRequest**](RequestPermissionRequest.md) |  | 

### Return type

[**RequestPermissionResponse**](RequestPermissionResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendCallEvent**
```swift
    open class func sendCallEvent(type: String, id: String, sendCallEventRequest: SendCallEventRequest, completion: @escaping (_ data: SendCallEventResponse?, _ error: Error?) -> Void)
```

Send custom event

Sends custom event to the call  Sends events: - custom  Required permissions: - SendEvent 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let sendCallEventRequest = SendCallEventRequest(custom: "TODO") // SendCallEventRequest | 

// Send custom event
ProductvideoAPI.sendCallEvent(type: type, id: id, sendCallEventRequest: sendCallEventRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **sendCallEventRequest** | [**SendCallEventRequest**](SendCallEventRequest.md) |  | 

### Return type

[**SendCallEventResponse**](SendCallEventResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sendVideoReaction**
```swift
    open class func sendVideoReaction(type: String, id: String, sendReactionRequest: SendReactionRequest, completion: @escaping (_ data: SendReactionResponse?, _ error: Error?) -> Void)
```

Send reaction to the call

Sends reaction to the call  Sends events: - call.reaction_new  Required permissions: - CreateCallReaction 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let sendReactionRequest = SendReactionRequest(custom: "TODO", emojiCode: "emojiCode_example", type: "type_example") // SendReactionRequest | 

// Send reaction to the call
ProductvideoAPI.sendVideoReaction(type: type, id: id, sendReactionRequest: sendReactionRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **sendReactionRequest** | [**SendReactionRequest**](SendReactionRequest.md) |  | 

### Return type

[**SendReactionResponse**](SendReactionResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startHLSBroadcasting**
```swift
    open class func startHLSBroadcasting(type: String, id: String, completion: @escaping (_ data: StartHLSBroadcastingResponse?, _ error: Error?) -> Void)
```

Start HLS broadcasting

Starts HLS broadcasting  Required permissions: - StartBroadcasting 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Start HLS broadcasting
ProductvideoAPI.startHLSBroadcasting(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**StartHLSBroadcastingResponse**](StartHLSBroadcastingResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startRTMPBroadcast**
```swift
    open class func startRTMPBroadcast(type: String, id: String, startRTMPBroadcastsRequest: StartRTMPBroadcastsRequest, completion: @escaping (_ data: StartRTMPBroadcastsResponse?, _ error: Error?) -> Void)
```

Start RTMP broadcasts

Starts RTMP broadcasts for the provided RTMP destinations  Required permissions: - StartBroadcasting 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let startRTMPBroadcastsRequest = StartRTMPBroadcastsRequest(layout: LayoutSettings(externalAppUrl: "externalAppUrl_example", externalCssUrl: "externalCssUrl_example", name: "name_example", options: "TODO"), name: "name_example", password: "password_example", quality: "quality_example", streamKey: "streamKey_example", streamUrl: "streamUrl_example", username: "username_example") // StartRTMPBroadcastsRequest | 

// Start RTMP broadcasts
ProductvideoAPI.startRTMPBroadcast(type: type, id: id, startRTMPBroadcastsRequest: startRTMPBroadcastsRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **startRTMPBroadcastsRequest** | [**StartRTMPBroadcastsRequest**](StartRTMPBroadcastsRequest.md) |  | 

### Return type

[**StartRTMPBroadcastsResponse**](StartRTMPBroadcastsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startRecording**
```swift
    open class func startRecording(type: String, id: String, startRecordingRequest: StartRecordingRequest, completion: @escaping (_ data: StartRecordingResponse?, _ error: Error?) -> Void)
```

Start recording

Starts recording  Sends events: - call.recording_started  Required permissions: - StartRecording 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let startRecordingRequest = StartRecordingRequest(recordingExternalStorage: "recordingExternalStorage_example") // StartRecordingRequest | 

// Start recording
ProductvideoAPI.startRecording(type: type, id: id, startRecordingRequest: startRecordingRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **startRecordingRequest** | [**StartRecordingRequest**](StartRecordingRequest.md) |  | 

### Return type

[**StartRecordingResponse**](StartRecordingResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startTranscription**
```swift
    open class func startTranscription(type: String, id: String, startTranscriptionRequest: StartTranscriptionRequest, completion: @escaping (_ data: StartTranscriptionResponse?, _ error: Error?) -> Void)
```

Start transcription

Starts transcription  Required permissions: - StartTranscription 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let startTranscriptionRequest = StartTranscriptionRequest(transcriptionExternalStorage: "transcriptionExternalStorage_example") // StartTranscriptionRequest | 

// Start transcription
ProductvideoAPI.startTranscription(type: type, id: id, startTranscriptionRequest: startTranscriptionRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **startTranscriptionRequest** | [**StartTranscriptionRequest**](StartTranscriptionRequest.md) |  | 

### Return type

[**StartTranscriptionResponse**](StartTranscriptionResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stopAllRTMPBroadcasts**
```swift
    open class func stopAllRTMPBroadcasts(type: String, id: String, completion: @escaping (_ data: StopAllRTMPBroadcastsResponse?, _ error: Error?) -> Void)
```

Stop all RTMP broadcasts for a call

Stop all RTMP broadcasts for the provided call  Required permissions: - StopBroadcasting 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Stop all RTMP broadcasts for a call
ProductvideoAPI.stopAllRTMPBroadcasts(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**StopAllRTMPBroadcastsResponse**](StopAllRTMPBroadcastsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stopHLSBroadcasting**
```swift
    open class func stopHLSBroadcasting(type: String, id: String, completion: @escaping (_ data: StopHLSBroadcastingResponse?, _ error: Error?) -> Void)
```

Stop HLS broadcasting

Stops HLS broadcasting  Required permissions: - StopBroadcasting 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Stop HLS broadcasting
ProductvideoAPI.stopHLSBroadcasting(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**StopHLSBroadcastingResponse**](StopHLSBroadcastingResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stopLive**
```swift
    open class func stopLive(type: String, id: String, completion: @escaping (_ data: StopLiveResponse?, _ error: Error?) -> Void)
```

Set call as not live

  Sends events: - call.updated  Required permissions: - UpdateCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Set call as not live
ProductvideoAPI.stopLive(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**StopLiveResponse**](StopLiveResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stopRTMPBroadcast**
```swift
    open class func stopRTMPBroadcast(type: String, id: String, name: String, body: [String: RawJSON], completion: @escaping (_ data: StopRTMPBroadcastsResponse?, _ error: Error?) -> Void)
```

Stop RTMP broadcasts

Stop RTMP broadcasts for the provided RTMP destinations  Required permissions: - StopBroadcasting 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let name = "name_example" // String | 
let body = "TODO" // [String: RawJSON] | 

// Stop RTMP broadcasts
ProductvideoAPI.stopRTMPBroadcast(type: type, id: id, name: name, body: body) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **name** | **String** |  | 
 **body** | **[String: RawJSON]** |  | 

### Return type

[**StopRTMPBroadcastsResponse**](StopRTMPBroadcastsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stopRecording**
```swift
    open class func stopRecording(type: String, id: String, completion: @escaping (_ data: StopRecordingResponse?, _ error: Error?) -> Void)
```

Stop recording

Stops recording  Sends events: - call.recording_stopped  Required permissions: - StopRecording 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Stop recording
ProductvideoAPI.stopRecording(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**StopRecordingResponse**](StopRecordingResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stopTranscription**
```swift
    open class func stopTranscription(type: String, id: String, completion: @escaping (_ data: StopTranscriptionResponse?, _ error: Error?) -> Void)
```

Stop transcription

Stops transcription  Sends events: - call.transcription_stopped  Required permissions: - StopTranscription 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 

// Stop transcription
ProductvideoAPI.stopTranscription(type: type, id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 

### Return type

[**StopTranscriptionResponse**](StopTranscriptionResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unblockUser**
```swift
    open class func unblockUser(type: String, id: String, unblockUserRequest: UnblockUserRequest, completion: @escaping (_ data: UnblockUserResponse?, _ error: Error?) -> Void)
```

Unblocks user on a call

Removes the block for a user on a call. The user will be able to join the call again.  Sends events: - call.unblocked_user  Required permissions: - BlockUser 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let unblockUserRequest = UnblockUserRequest(userId: "userId_example") // UnblockUserRequest | 

// Unblocks user on a call
ProductvideoAPI.unblockUser(type: type, id: id, unblockUserRequest: unblockUserRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **unblockUserRequest** | [**UnblockUserRequest**](UnblockUserRequest.md) |  | 

### Return type

[**UnblockUserResponse**](UnblockUserResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateCall**
```swift
    open class func updateCall(type: String, id: String, updateCallRequest: UpdateCallRequest, completion: @escaping (_ data: UpdateCallResponse?, _ error: Error?) -> Void)
```

Update Call

  Sends events: - call.updated  Required permissions: - UpdateCall 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let updateCallRequest = UpdateCallRequest(custom: "TODO", settingsOverride: CallSettingsRequest(audio: AudioSettingsRequest(accessRequestEnabled: false, defaultDevice: "defaultDevice_example", micDefaultOn: false, noiseCancellation: NoiseCancellationSettings(mode: "mode_example"), opusDtxEnabled: false, redundantCodingEnabled: false, speakerDefaultOn: false), backstage: BackstageSettingsRequest(enabled: false, joinAheadTimeSeconds: 123), broadcasting: BroadcastSettingsRequest(enabled: false, hls: HLSSettingsRequest(autoOn: false, enabled: false, qualityTracks: ["qualityTracks_example"]), rtmp: RTMPSettingsRequest(enabled: false, maxDurationMinutes: 123, quality: "quality_example")), geofencing: GeofenceSettingsRequest(names: ["names_example"]), limits: LimitsSettingsRequest(maxDurationSeconds: 123, maxParticipants: 123), recording: RecordSettingsRequest(audioOnly: false, mode: "mode_example", quality: "quality_example"), ring: RingSettingsRequest(autoCancelTimeoutMs: 123, incomingCallTimeoutMs: 123, missedCallTimeoutMs: 123), screensharing: ScreensharingSettingsRequest(accessRequestEnabled: false, enabled: false, targetResolution: TargetResolution(bitrate: 123, height: 123, width: 123)), thumbnails: ThumbnailsSettingsRequest(enabled: false), transcription: TranscriptionSettingsRequest(closedCaptionMode: "closedCaptionMode_example", languages: ["languages_example"], mode: "mode_example"), video: VideoSettingsRequest(accessRequestEnabled: false, cameraDefaultOn: false, cameraFacing: "cameraFacing_example", enabled: false, targetResolution: nil)), startsAt: Date()) // UpdateCallRequest | 

// Update Call
ProductvideoAPI.updateCall(type: type, id: id, updateCallRequest: updateCallRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **updateCallRequest** | [**UpdateCallRequest**](UpdateCallRequest.md) |  | 

### Return type

[**UpdateCallResponse**](UpdateCallResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateCallMembers**
```swift
    open class func updateCallMembers(type: String, id: String, updateCallMembersRequest: UpdateCallMembersRequest, completion: @escaping (_ data: UpdateCallMembersResponse?, _ error: Error?) -> Void)
```

Update Call Member

  Sends events: - call.member_added - call.member_removed - call.member_updated  Required permissions: - RemoveCallMember - UpdateCallMember - UpdateCallMemberRole 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let updateCallMembersRequest = UpdateCallMembersRequest(removeMembers: ["removeMembers_example"], updateMembers: [MemberRequest(custom: "TODO", role: "role_example", userId: "userId_example")]) // UpdateCallMembersRequest | 

// Update Call Member
ProductvideoAPI.updateCallMembers(type: type, id: id, updateCallMembersRequest: updateCallMembersRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **updateCallMembersRequest** | [**UpdateCallMembersRequest**](UpdateCallMembersRequest.md) |  | 

### Return type

[**UpdateCallMembersResponse**](UpdateCallMembersResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUserPermissions**
```swift
    open class func updateUserPermissions(type: String, id: String, updateUserPermissionsRequest: UpdateUserPermissionsRequest, completion: @escaping (_ data: UpdateUserPermissionsResponse?, _ error: Error?) -> Void)
```

Update user permissions

Updates user permissions  Sends events: - call.permissions_updated  Required permissions: - UpdateCallPermissions 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let updateUserPermissionsRequest = UpdateUserPermissionsRequest(grantPermissions: ["grantPermissions_example"], revokePermissions: ["revokePermissions_example"], userId: "userId_example") // UpdateUserPermissionsRequest | 

// Update user permissions
ProductvideoAPI.updateUserPermissions(type: type, id: id, updateUserPermissionsRequest: updateUserPermissionsRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **updateUserPermissionsRequest** | [**UpdateUserPermissionsRequest**](UpdateUserPermissionsRequest.md) |  | 

### Return type

[**UpdateUserPermissionsResponse**](UpdateUserPermissionsResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **videoConnect**
```swift
    open class func videoConnect(completion: @escaping (_ data: Void?, _ error: Error?) -> Void)
```

Video Connect (WebSocket)

Establishes WebSocket connection for user to video  Sends events: - connection.ok - health.check 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Video Connect (WebSocket)
ProductvideoAPI.videoConnect() { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

Void (empty response body)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **videoPin**
```swift
    open class func videoPin(type: String, id: String, pinRequest: PinRequest, completion: @escaping (_ data: PinResponse?, _ error: Error?) -> Void)
```

Pin

Pins a track for all users in the call.  Required permissions: - PinCallTrack 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let pinRequest = PinRequest(sessionId: "sessionId_example", userId: "userId_example") // PinRequest | 

// Pin
ProductvideoAPI.videoPin(type: type, id: id, pinRequest: pinRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **pinRequest** | [**PinRequest**](PinRequest.md) |  | 

### Return type

[**PinResponse**](PinResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **videoUnpin**
```swift
    open class func videoUnpin(type: String, id: String, unpinRequest: UnpinRequest, completion: @escaping (_ data: UnpinResponse?, _ error: Error?) -> Void)
```

Unpin

Unpins a track for all users in the call.  Required permissions: - PinCallTrack 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let type = "type_example" // String | 
let id = "id_example" // String | 
let unpinRequest = UnpinRequest(sessionId: "sessionId_example", userId: "userId_example") // UnpinRequest | 

// Unpin
ProductvideoAPI.videoUnpin(type: type, id: id, unpinRequest: unpinRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String** |  | 
 **id** | **String** |  | 
 **unpinRequest** | [**UnpinRequest**](UnpinRequest.md) |  | 

### Return type

[**UnpinResponse**](UnpinResponse.md)

### Authorization

[stream-auth-type](../README.md#stream-auth-type), [api_key](../README.md#api_key), [JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

