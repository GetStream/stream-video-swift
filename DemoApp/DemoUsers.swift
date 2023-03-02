//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct UserCredentials: Identifiable, Codable {
    var id: String {
        userInfo.id
    }
    let userInfo: User
    let token: UserToken
}

extension User {
    
    static func builtInUsersByID(id: String) -> User? {
        builtInUsers.filter { $0.id == id }.first
    }
    
    static var builtInUsers: [User] = [
        (
            "martin",
            "Martin",
            "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp"
        ),
        (
            "tommaso",
            "Tommaso",
            "https://getstream.io/static/712bb5c0bd5ed8d3fa6e5842f6cfbeed/c59de/tommaso.webp"
        ),
        (
            "marcelo",
            "Marcelo",
            "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp"
        ),
        (
            "filip",
            "Filip",
            "https://getstream.io/static/76cda49669be38b92306cfc93ca742f1/802d2/filip-babi%C4%87.webp"
        ),
        (
            "thierry",
            "Thierry",
            "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp"
        ),
        (
            "oliver",
            "Oliver",
            "https://getstream.io/static/b8a66e9095cf9c73316db18b8c1200b5/802d2/oliver-lazoroski.webp"
        )
    ].map {
        User(
            id: $0.0,
            name: $0.1,
            imageURL: URL(string: $0.2)!,
            extraData: [:]
        )
    }
}
