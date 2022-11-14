//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension StreamVideo {
    public static var mockUser = User(
        id: "testuser",
        name: "Test User",
        imageURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
        extraData: [:]
    )
    
    public static var mockToken = try! UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90ZXN0dXNlciIsImlhdCI6MTY2NjY5ODczMSwidXNlcl9pZCI6InRlc3R1c2VyIn0.h4lnaF6OFYaNPjeK8uFkKirR5kHtj1vAKuipq3A5nM0")
    
    static func mock(httpClient: HTTPClient) -> StreamVideo {
        let environment = Environment(httpClientBuilder: { _ in
            httpClient
        })
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: mockUser,
            token: mockToken,
            tokenProvider: { result in
                result(.success(mockToken))
            },
            environment: environment
        )
        return streamVideo
    }
}
