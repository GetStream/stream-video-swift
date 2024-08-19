# Poll

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**custom** | **[String: RawJSON]** |  | 
**allowAnswers** | **Bool** |  | 
**allowUserSuggestedOptions** | **Bool** |  | 
**answersCount** | **Int** |  | 
**createdAt** | **Date** |  | 
**createdBy** | [**UserObject**](UserObject.md) |  | [optional] 
**createdById** | **String** |  | 
**description** | **String** |  | 
**enforceUniqueVote** | **Bool** |  | 
**id** | **String** |  | 
**isClosed** | **Bool** |  | [optional] 
**latestAnswers** | [PollVote] |  | 
**latestVotesByOption** | [String: [PollVote]] |  | 
**maxVotesAllowed** | **Int** |  | [optional] 
**name** | **String** |  | 
**options** | [PollOption] |  | 
**ownVotes** | [PollVote] |  | 
**updatedAt** | **Date** |  | 
**voteCount** | **Int** |  | 
**voteCountsByOption** | **[String: Int]** |  | 
**votingVisibility** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


