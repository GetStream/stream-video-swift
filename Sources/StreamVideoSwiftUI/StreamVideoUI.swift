//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo

public class StreamVideoUI {
    var streamVideo: StreamVideo
    var appearance: Appearance
    var utils: Utils
    
    public convenience init(
        apiKey: String,
        user: UserInfo,
        token: Token,
        videoConfig: VideoConfig = VideoConfig(),
        tokenProvider: @escaping TokenProvider,
        appearance: Appearance = Appearance(),
        utils: Utils = Utils()
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
    
    public init(
        streamVideo: StreamVideo,
        appearance: Appearance = Appearance(),
        utils: Utils = Utils()
    ) {
        self.streamVideo = streamVideo
        self.appearance = appearance
        self.utils = utils
        AppearanceKey.currentValue = appearance
        UtilsKey.currentValue = utils
    }
}

extension InjectedValues {
    
    /// Provides access to the `Colors` instance.
    public var colors: Colors {
        get {
            appearance.colors
        }
        set {
            appearance.colors = newValue
        }
    }
    
    /// Provides access to the `Images` instance.
    public var images: Images {
        get {
            appearance.images
        }
        set {
            appearance.images = newValue
        }
    }
    
    /// Provides access to the `Fonts` instance.
    public var fonts: Fonts {
        get {
            appearance.fonts
        }
        set {
            appearance.fonts = newValue
        }
    }
    
    /// Provides access to the `Sounds` instance.
    public var sounds: Sounds {
        get {
            appearance.sounds
        }
        set {
            appearance.sounds = newValue
        }
    }
}
