# UserObject

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**banExpires** | **Date** | Expiration date of the ban | [optional] 
**banned** | **Bool** | Whether a user is banned or not | 
**createdAt** | **Date** | Date/time of creation | [optional] [readonly] 
**custom** | **[String: RawJSON]** |  | 
**deactivatedAt** | **Date** | Date of deactivation | [optional] [readonly] 
**deletedAt** | **Date** | Date/time of deletion | [optional] [readonly] 
**id** | **String** | Unique user identifier | 
**invisible** | **Bool** |  | [optional] 
**language** | **String** | Preferred language of a user | [optional] 
**lastActive** | **Date** | Date of last activity | [optional] [readonly] 
**online** | **Bool** | Whether a user online or not | [readonly] 
**privacySettings** | [**PrivacySettings**](PrivacySettings.md) |  | [optional] 
**pushNotifications** | [**PushNotificationSettings**](PushNotificationSettings.md) |  | [optional] 
**revokeTokensIssuedBefore** | **Date** | Revocation date for tokens | [optional] 
**role** | **String** | Determines the set of user permissions | 
**teams** | **[String]** | List of teams user is a part of | [optional] 
**updatedAt** | **Date** | Date/time of the last update | [optional] [readonly] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


