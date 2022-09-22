//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

@MainActor
class LoginViewModel: ObservableObject {
        
    @Published var loading = false
    
    @Published var userCredentials = UserCredentials.builtInUsers
    
    func login(user: UserCredentials, completion: (UserCredentials) -> ()) {
        AppState.shared.userState = .loggedIn
        // Perform login
        completion(user)
    }
    
}

struct UserCredentials: Identifiable {
    var id: String {
        userInfo.id
    }
    let userInfo: UserInfo
    let token: Token
}

extension UserCredentials {
    
    static func builtInUsersByID(id: String) -> UserCredentials? {
        builtInUsers.filter { $0.id == id }.first
    }
    
    static var builtInUsers: [UserCredentials] = [
        (
            "tommaso",
            "Tommaso",
            "https://getstream.io/static/712bb5c0bd5ed8d3fa6e5842f6cfbeed/c59de/tommaso.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90b21tYXNvIiwiaWF0IjoxNjYzODM3Njg0LCJ1c2VyX2lkIjoidG9tbWFzbyJ9.yYt4xvqEP18TBlheEc88lqPRHmbJc6-hs71Lvmwc2k8"
        ),
        (
            "marcelo",
            "Marcelo",
            "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9tYXJjZWxvIiwiaWF0IjoxNjYzODM3NzA3LCJ1c2VyX2lkIjoibWFyY2VsbyJ9.8m4Gf0mtbgkELLeHiumA6jndvhYABbaesjEpb8Y1bG4"
        ),
        (
            "martin",
            "Martin",
            "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9tYXJ0aW4iLCJpYXQiOjE2NjM4Mzc2NTEsInVzZXJfaWQiOiJtYXJ0aW4ifQ.Rk68sAq1y2onI1qcCiDGAUV8hZNUp9XCspwdalqu27Y"
        ),
        (
            "filip",
            "Filip",
            "https://getstream.io/static/76cda49669be38b92306cfc93ca742f1/802d2/filip-babi%C4%87.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9maWxpcCIsImlhdCI6MTY2MzgzNzcyNSwidXNlcl9pZCI6ImZpbGlwIn0.iv6C5qJKFyvWhbKsXKGVToyfo63P5fAyLJW0h517vSk"
        ),
        (
            "thierry",
            "Thierry",
            "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90aGllcnJ5IiwiaWF0IjoxNjYzODM3NzQxLCJ1c2VyX2lkIjoidGhpZXJyeSJ9.pPi5OaX8rOe2EoLa-mhUiV7ydudZnQZgggZv5b6E2dc"
        ),
        (
            "sam",
            "Sam",
            "https://getstream.io/static/379eda22663bae101892ad1d37778c3d/802d2/samuel-jeeves.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9zYW0iLCJpYXQiOjE2NjM4Mzc3NTQsInVzZXJfaWQiOiJzYW0ifQ.44NnYzb6-kkI7q4cNt0CUaDJBf1qoZJmNLg7evO5_r4"
        )
    ].map {
        UserCredentials(
            userInfo: UserInfo(
                id: $0.0,
                name: $0.1,
                imageURL: URL(string: $0.2)!,
                extraData: [:]
            ),
            token: try! Token(rawValue: $0.3)
        )
    }
}
