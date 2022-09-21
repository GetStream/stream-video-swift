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
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90b21tYXNvIiwiZXhwIjoxNjYzODM3NzYxLCJpYXQiOjE2NjM3NTEzNjEsInVzZXJfaWQiOiJ0b21tYXNvIn0.-ZfSwcCar_0WjflUqH7RPtZKa-b3CG7RlHY0oLSJ3iE"
        ),
        (
            "marcelo",
            "Marcelo",
            "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9tYXJjZWxvIiwiZXhwIjoxNjYzODM3Nzg0LCJpYXQiOjE2NjM3NTEzODQsInVzZXJfaWQiOiJtYXJjZWxvIn0.LqVynuaqzFD3vJKBS6ENd__oT7IFML3-tMYz-rfBHyM"
        ),
        (
            "martin",
            "Martin",
            "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9tYXJ0aW4iLCJleHAiOjE2NjM4NDg4NzMsImlhdCI6MTY2Mzc2MjQ3MywidXNlcl9pZCI6Im1hcnRpbiJ9.Opue6gr4FRRE5r1P9IF21BJdjDb-ScOy1Yfzc3BUs44"
        ),
        (
            "filip",
            "Filip",
            "https://getstream.io/static/76cda49669be38b92306cfc93ca742f1/802d2/filip-babi%C4%87.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9maWxpcCIsImV4cCI6MTY2MzgzNzg1MCwiaWF0IjoxNjYzNzUxNDUwLCJ1c2VyX2lkIjoiZmlsaXAifQ.JDpFiE1lcBgKy8yDEA8w26pRd57PDgBa_4jQSqfKix4"
        ),
        (
            "thierry",
            "Thierry",
            "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90aGllcnJ5IiwiZXhwIjoxNjYzODM3ODY4LCJpYXQiOjE2NjM3NTE0NjgsInVzZXJfaWQiOiJ0aGllcnJ5In0.2sVZ5LYx09kLwISn4iYDO3yJMlJjtvL6aZX9CDd6DMc"
        ),
        (
            "sam",
            "Sam",
            "https://getstream.io/static/379eda22663bae101892ad1d37778c3d/802d2/samuel-jeeves.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9zYW0iLCJleHAiOjE2NjM4Mzc4ODYsImlhdCI6MTY2Mzc1MTQ4NiwidXNlcl9pZCI6InNhbSJ9.yIFjUTBQnnRlUFL6AfGf23vEZ0nIJv49pHlvq9-dWo0"
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
