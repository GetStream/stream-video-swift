---
title: Authentication
---

Stream uses JWT (JSON Web Tokens) to authenticate video users, enabling them to login. The same token can be used to login into our chat services (provided that your app ID is enabled for both chat and video).

For security reasons, you cannot generate User Tokens from the Video SDK in the front end and you must request them from your token provider endpoint. If you do not have a token provider endpoint during your development phase, you can manually generate tokens for getting started [here](https://generator.getstream.io). It's important to note that you should not use them in production.

### Token Providers

At a high level, the Token Provider is an endpoint on your server that can perform the following sequence of tasks:

- Receive information about a user from the front end.
- Validate that user information against your system.
- Provide a User-ID corresponding to that user to the server client's token creation method.
- Return that token to the front end.

User Tokens can only be safely generated from a server. This means you will need to implement a Token Provider prior to deploying your application to production. 

### StreamVideo client

The `StreamVideo` client requires a token and a token provider to be initialized. If the provided token has an expiry date (which we strongly recommend), the token provider closure would be invoked when the token expires, giving you a chance to refresh it.

Here is an example initialization of the `StreamVideo` client:

```swift
let streamVideo = StreamVideo(
    apiKey: "your_api_key",
    user: user.userInfo,
    token: user.token,
    videoConfig: VideoConfig(),
    tokenProvider: { result in
        Task {
            let newToken = try await fetchToken(for: user.userInfo)
            result(.success(newToken))
        }
    }
)
```

Note the `fetchToken` method. In this method, you will need to provide your own implementation, that will load a new token for the current user. As soon as you provide the token in the `result`, the SDK will be notified about the new token and retry the failed request.

When the object is created, you should connect the user to our backend. This can be done whenever you plan on using the video features.

```swift
private func connectUser() {
    Task {
        try await streamVideo?.connect()
    }
}
```

#### Guest users

Another type of users are guest users. Guests can perform web socket connection and join a call (depending on the configured permissions). Also, guests are able to send audio and video to a call.

Creating a `StreamVideo` client for a guest user is an async and throwing operation, since we are fetching a guest token for the user to join a call in the background. 

Here's an example initialization of the `StreamVideo` client for guest users:

```swift
Task {
    let streamVideo = try await StreamVideo(apiKey: "api_key", user: .guest("martin"))
}
```

After the client is initialized, you can safely create a `CallViewModel` and join calls, like a regular user.

#### Anonymous users

Anonymous users don't have a profile. They are not able to send audio or video, and they are not able to perform a web socket connection. If you try to call the `connect` method for an anonymous user, a `MissingPermission` error will be thrown.

Anonymous users need a call token to join a call. Call tokens are JWT authentication tokens that include additional claims that grant special access to a list of calls. They allow anonymous users to have access to a list of calls.

Few important things about call tokens:
- Call tokens must have an expiration time included to avoid security problems.
- Call tokens can contain up to 100 call ids.
- Call tokens for anonymous users must be generated with the special `!anon` `user_id` claim.
- Membership / role can only be invalidated using the existing API around token invalidation (we invalidate all tokens for a user).
- Generating a call token does not require any API interaction and can be done with any server-side SDK.

The call token should contain `user_id="!anon"`, as well as the list of supported call ids `call_cids=["default:1", "default:2"]`.

In order to create a `StreamVideo` client for an anonymous user, you need to provide the `.anonymous` `User` type:

```swift
let streamVideo = StreamVideo(apiKey: "api_key", user: .anonymous, token: serverSideGeneratedToken) { result in
    Task {
        do {
            let token = try await TokenService.shared.fetchToken(for: user.id)
            result(.success(token))
        } catch {
            result(.failure(error))
        }
    }
}
```

Alternatively, you can skip the `tokenProvider` parameter which is called when a token expires. In that case, the user will have an invalid token and will not be able to be part of the call anymore.

```swift
let streamVideo = StreamVideo(apiKey: "api_key", user: .anonymous, token: serverSideGeneratedToken)
```