//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo

private enum First {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: user,
        token: token,
        tokenProvider: { _ in }
    )
}

private enum Second {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: .guest("guest"),
        token: token,
        tokenProvider: { _ in }
    )
}

private enum Third {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: .anonymous,
        token: token,
        tokenProvider: { _ in }
    )
}

private enum Fourth {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: user,
        token: token,
        videoConfig: VideoConfig(),
        pushNotificationsConfig: .default,
        tokenProvider: { _ in }
    )
}
