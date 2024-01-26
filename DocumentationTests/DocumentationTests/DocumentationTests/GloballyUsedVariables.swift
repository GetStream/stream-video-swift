import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

var apiKey = ""
var user = User(id: "")
var token = UserToken(stringLiteral: "")
var tokenProvider: UserTokenProvider = { _ in }
var streamVideo = StreamVideo(apiKey: apiKey, user: user, token: token)
var call = streamVideo.call(callType: "default", callId: UUID().uuidString)
@MainActor var viewModel = CallViewModel()
@MainActor var viewFactory = DefaultViewFactory.shared

func container(_ content: () -> Void) {}
func asyncContainer(_ content: () async throws -> Void) {}
func viewContainer(@ViewBuilder _ content: () -> some View) {}

struct UserCredentials {
    let user: User
    let token: UserToken
}

extension UserCredentials {
    static let demoUser = UserCredentials(
        user: User(
            id: "testuser",
            name: "Test User",
            imageURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
            customData: [:]
        ),
        token: UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90ZXN0dXNlciIsImlhdCI6MTY2NjY5ODczMSwidXNlcl9pZCI6InRlc3R1c2VyIn0.h4lnaF6OFYaNPjeK8uFkKirR5kHtj1vAKuipq3A5nM0")
    )
}
