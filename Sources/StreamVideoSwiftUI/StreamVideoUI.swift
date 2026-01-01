//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo

public class StreamVideoUI {
    var streamVideo: StreamVideo
    var appearance: Appearance
    var utils: Utils
    
    /// Initializes a new instance of `StreamVideoUI` with the specified parameters.
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - user: The `User` who is currently logged in.
    ///   - token: The `UserToken` used to authenticate the user.
    ///   - videoConfig: A `VideoConfig` instance representing the video config.
    ///   - tokenProvider: A closure that provides a `UserToken` for the specified `User`.
    ///   - appearance: The `Appearance` instance to use for customizing the appearance of the user interface.
    ///   - utils: The `Utils` instance to use for utility functions.
    /// - Returns: A new instance of `StreamVideoUI`.
    public convenience init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping UserTokenProvider,
        appearance: Appearance = Appearance(),
        utils: Utils = UtilsKey.currentValue
    ) {
        let streamVideo = StreamVideo(
            apiKey: apiKey,
            user: user,
            token: token,
            videoConfig: videoConfig,
            tokenProvider: tokenProvider
        )
        self.init(
            streamVideo: streamVideo,
            appearance: appearance,
            utils: utils
        )
    }
    
    /// Initializes a new instance of `StreamVideoUI` with the specified parameters.
    /// - Parameters:
    ///   - streamVideo: The `StreamVideo` instance.
    ///   - appearance: The `Appearance` instance to use for customizing the appearance of the user interface.
    ///   - utils: The `Utils` instance to use for utility functions.
    /// - Returns: A new instance of `StreamVideoUI`.
    public init(
        streamVideo: StreamVideo,
        appearance: Appearance = Appearance(),
        utils: Utils = UtilsKey.currentValue
    ) {
        self.streamVideo = streamVideo
        self.appearance = appearance
        self.utils = utils
        AppearanceKey.currentValue = appearance
        UtilsKey.currentValue = utils
    }
    
    /// Connects the current user.
    public func connect() async throws {
        try await streamVideo.connect()
    }
}
