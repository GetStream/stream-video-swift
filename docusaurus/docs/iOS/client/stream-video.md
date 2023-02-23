:::warning
Requires writing
:::

# StreamVideo

This is the main object for interfacing with the low-level client. It needs to be initialized with an API key and a user/token, before the SDK can be used.

```swift
let streamVideo = StreamVideo(
    apiKey: "key1",
    user: user.userInfo,
    token: user.token,
    videoConfig: VideoConfig(),
    tokenProvider: { result in
    	yourNetworkService.loadToken(completion: result)
    }
)
```

Here are parameters that the `StreamVideo` class expects:

- `apiKey` - your Stream Video API key (note: it's different from chat)
- `user` - the logged in user, represented by the `UserInfo` struct.
- `token` - the user's token.
- `videoConfig` - configuration for the type of calls.
- `tokenProvider` - called when the token expires. Use it to load a new token from your networking service.

The `StreamVideo` object should be kept alive throughout the app lifecycle. You can store it in your `App` or `AppDelegate`, or any other class whose lifecycle is tied to the one of the logged in user.
