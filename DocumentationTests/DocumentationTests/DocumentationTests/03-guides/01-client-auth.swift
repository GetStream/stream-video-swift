import StreamVideo

fileprivate enum First {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: user,
        token: token,
        tokenProvider: { _ in }
    )
}

fileprivate enum Second {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: .guest("guest"),
        token: token,
        tokenProvider: { _ in }
    )
}

fileprivate enum Third {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: .anonymous,
        token: token,
        tokenProvider: { _ in }
    )
}

fileprivate enum Fourth {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: user,
        token: token,
        videoConfig: VideoConfig(),
        pushNotificationsConfig: .default,
        tokenProvider: { _ in }
    )
}
