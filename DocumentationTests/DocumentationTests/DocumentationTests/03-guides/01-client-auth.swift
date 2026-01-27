//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo

private enum First {
    static let streamVideo = StreamVideo(
        apiKey: apiKey,
        user: user,
        token: token,
        tokenProvider: { _ in
            // Called when the token expires. Fetch a new token from your backend.
            // Call result(.success(newToken)) or result(.failure(error))
        }
    )
}

@MainActor
private func content() {
    asyncContainer {
        try await streamVideo.connect()
    }

    asyncContainer {
        await streamVideo.disconnect()
    }
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
