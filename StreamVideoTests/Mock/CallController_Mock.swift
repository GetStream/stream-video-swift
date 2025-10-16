//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

class CallController_Mock: CallController, @unchecked Sendable {

    let mockResponseBuilder = MockResponseBuilder()

    @MainActor func update(participants: [String: CallParticipant]) {
        call?.state.participantsMap = participants
    }

    override func joinCall(
        create: Bool = true,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false,
        source: JoinSource
    ) async throws -> JoinCallResponse {
        mockResponseBuilder.makeJoinCallResponse(cid: super.call?.cId ?? "default:\(String.unique)")
    }

    override func changeAudioState(isEnabled: Bool, file: StaticString, function: StaticString, line: UInt) async throws {
    /* no op */ }

    override func changeVideoState(isEnabled: Bool) async throws { /* no op */ }

    override func changeCameraMode(position: CameraPosition) async throws { /* no op */ }

    override func changeSoundState(isEnabled: Bool) async throws { /* no op */ }

    override func changeSpeakerState(isEnabled: Bool) async throws { /* no op */ }
}

extension CallController_Mock {
    static func make() -> CallController_Mock {
        CallController_Mock(
            defaultAPI: DefaultAPI(
                basePath: "test.com",
                transport: HTTPClient_Mock(),
                middlewares: []
            ),
            user: StreamVideo.mockUser,
            callId: "123",
            callType: "default",
            apiKey: "key1",
            videoConfig: .dummy(),
            cachedLocation: nil
        )
    }
}

extension DefaultAPI {

    static func dummy(
        basePath: String = "getstream.io",
        transport: DefaultAPITransport = HTTPClient_Mock(),
        middlewares: [DefaultAPIClientMiddleware] = []
    ) -> DefaultAPI {
        .init(
            basePath: basePath,
            transport: transport,
            middlewares: middlewares
        )
    }
}

extension CallController {
    static func dummy(
        defaultAPI: DefaultAPIEndpoints = MockDefaultAPIEndpoints(),
        user: User = .dummy(),
        callId: String = .unique,
        callType: String = .default,
        apiKey: String = .unique,
        videoConfig: VideoConfig = .init(),
        cachedLocation: String? = nil
    ) -> CallController {
        .init(
            defaultAPI: defaultAPI,
            user: user,
            callId: callId,
            callType: callType,
            apiKey: apiKey,
            videoConfig: videoConfig,
            cachedLocation: cachedLocation
        )
    }
}

extension User {
    static func dummy(
        id: String = .unique,
        name: String = .unique,
        imageURL: URL? = nil,
        role: String = "regular",
        type: UserAuthType = .regular,
        customData: [String: RawJSON] = [:]
    ) -> User {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            role: role,
            type: type,
            customData: customData
        )
    }
}

extension Call {
    static func dummy(
        callType: String = .default,
        callId: String = .unique,
        coordinatorClient: DefaultAPI = .dummy(),
        callController: CallController? = nil
    ) -> Call {
        .init(
            callType: callType,
            callId: callId,
            coordinatorClient: coordinatorClient,
            callController: callController ?? .dummy(
                defaultAPI: coordinatorClient,
                callId: callId,
                callType: callType
            )
        )
    }
}
