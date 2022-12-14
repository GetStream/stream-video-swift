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