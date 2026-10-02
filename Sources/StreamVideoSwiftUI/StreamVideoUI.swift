//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo

public class StreamVideoUI {
    var streamVideo: StreamVideo
    var videoAppearance: VideoAppearance
    var utils: Utils
    
    /// Initializes a new instance of `StreamVideoUI` with the specified parameters.
    /// - Parameters:
    ///   - apiKey: The API key.
    ///   - user: The `User` who is currently logged in.
    ///   - token: The `UserToken` used to authenticate the user.
    ///   - videoConfig: A `VideoConfig` instance representing the video config.
    ///   - tokenProvider: A closure that provides a `UserToken` for the specified `User`.
    ///   - videoAppearance: The design-system appearance used to customize the user interface.
    ///   - utils: The `Utils` instance to use for utility functions.
    /// - Returns: A new instance of `StreamVideoUI`.
    public convenience init(
        apiKey: String,
        user: User,
        token: UserToken,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping UserTokenProvider,
        videoAppearance: VideoAppearance = .shared,
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
            videoAppearance: videoAppearance,
            utils: utils
        )
    }
    
    /// Initializes a new instance of `StreamVideoUI` with the specified parameters.
    /// - Parameters:
    ///   - streamVideo: The `StreamVideo` instance.
    ///   - videoAppearance: The design-system appearance used to customize the user interface.
    ///   - utils: The `Utils` instance to use for utility functions.
    /// - Returns: A new instance of `StreamVideoUI`.
    public init(
        streamVideo: StreamVideo,
        videoAppearance: VideoAppearance = .shared,
        utils: Utils = UtilsKey.currentValue
    ) {
        self.streamVideo = streamVideo
        self.videoAppearance = videoAppearance
        self.utils = utils
        VideoAppearanceKey.currentValue = videoAppearance
        UtilsKey.currentValue = utils
    }
    
    /// Connects the current user.
    public func connect() async throws {
        try await streamVideo.connect()
    }
}
