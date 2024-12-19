//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

extension StreamVideoCapturer {

    static func mock(
        videoSource: RTCVideoSource
    ) -> StreamVideoCapturer {
        .init(
            videoSource: videoSource,
            videoCapturer: .init(),
            videoCapturerDelegate: MockRTCVideoCapturerDelegate(),
            actionHandlers: [
                MockStreamVideoCapturerActionHandler()
            ]
        )
    }

    func add(
        _ delegateHandler: @escaping (StreamVideoCapturer.Action) async throws -> Void
    ) {
        guard let mockActionHandler: MockStreamVideoCapturerActionHandler = actionHandler() else {
            return
        }
        mockActionHandler.delegateHandler = delegateHandler
    }
}

final class MockStreamVideoCapturerActionHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {
    private(set) var receivedActions: [StreamVideoCapturer.Action] = []

    var delegateHandler: ((StreamVideoCapturer.Action) async throws -> Void)?

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        receivedActions.append(action)
        try await delegateHandler?(action)
    }
}
