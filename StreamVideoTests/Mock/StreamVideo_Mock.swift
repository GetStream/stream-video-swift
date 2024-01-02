//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension StreamVideo {
    static var apiKey = "key1"
    static var mockUser = User(
        id: "testuser",
        name: "Test User",
        imageURL: ImageFactory.get(0),
        customData: [:]
    )
    
    static var mockToken = UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90ZXN0dXNlciIsImlhdCI6MTY2NjY5ODczMSwidXNlcl9pZCI6InRlc3R1c2VyIn0.h4lnaF6OFYaNPjeK8uFkKirR5kHtj1vAKuipq3A5nM0")
    
    static func mock(
        httpClient: HTTPClient,
        callController: CallController? = nil
    ) -> StreamVideo {
        let streamVideo = StreamVideo(
            apiKey: apiKey,
            user: mockUser,
            token: mockToken,
            tokenProvider: { result in
                result(.success(mockToken))
            },
            pushNotificationsConfig: .default,
            environment: mockEnvironment(httpClient, callController)
        )
        return streamVideo
    }
    
    static func mockEnvironment(
        _ httpClient: HTTPClient,
        _ callController: CallController? = nil
    ) -> Environment {
        return Environment(
            callControllerBuilder: { defaultAPI, user, callId, callType, apiKey, videoConfig, cachedLocation  in
            callController ?? CallController_Mock(
                defaultAPI: defaultAPI,
                user: user,
                callId: callId,
                callType: callType,
                apiKey: apiKey,
                videoConfig: videoConfig,
                cachedLocation: cachedLocation
            )
            }) { tokenProvider in
                httpClient as! any DefaultAPITransport
            }
    }
    
}
