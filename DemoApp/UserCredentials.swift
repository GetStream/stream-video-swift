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

extension UserCredentials {
    
    static func builtInUsersByID(id: String) -> UserCredentials? {
        builtInUsers.filter { $0.id == id }.first
    }
    
    static var builtInUsers: [UserCredentials] = [
        (
            "oliver.lazoroski@getstream.io",
            "Oliver",
            "https://getstream.io/static/712bb5c0bd5ed8d3fa6e5842f6cfbeed/c59de/tommaso.webp",
            token(for: "oliver.lazoroski@getstream.io", config: .frankfurt)
        ),
        (
            "marcelo",
            "Marcelo",
            "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9tYXJjZWxvIiwiaWF0IjoxNjcwMzM5NDU2LCJ1c2VyX2lkIjoibWFyY2VsbyJ9.-tBPUvyU-XTh04f9-Owv9tB6EG0lEIAyHTsZXYwOTqw"
        ),
        (
            "martin",
            "Martin",
            "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp",
            token(for: "martin", config: .frankfurt)
        ),
        (
            "filip",
            "Filip",
            "https://getstream.io/static/76cda49669be38b92306cfc93ca742f1/802d2/filip-babi%C4%87.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9maWxpcCIsImlhdCI6MTY3MDMzOTQ4MSwidXNlcl9pZCI6ImZpbGlwIn0.rGK-twVawPRItb_xQigYuYVO8UDTCCNPYKM5xP6mpbo"
        ),
        (
            "thierry",
            "Thierry",
            "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci90aGllcnJ5IiwiaWF0IjoxNjcwMzM5NTAwLCJ1c2VyX2lkIjoidGhpZXJyeSJ9.q8dy763W-ZVOA_1VbNhz0VozuxAI1Ko42HlVl-9mnG8"
        ),
        (
            "sam",
            "Sam",
            "https://getstream.io/static/379eda22663bae101892ad1d37778c3d/802d2/samuel-jeeves.webp",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tZ29AdjAuMS4wIiwic3ViIjoidXNlci9zYW0iLCJpYXQiOjE2NzAzMzk1MTUsInVzZXJfaWQiOiJzYW0ifQ.CDmyx9nQlWpqopuoQDP4p7caeGt_r51dLbg9uVO45OA"
        )
    ].map {
        UserCredentials(
            userInfo: User(
                id: $0.0,
                name: $0.1,
                imageURL: URL(string: $0.2)!,
                extraData: [:]
            ),
            token: try! UserToken(rawValue: $0.3)
        )
    }
    
    //TODO: temp
    static func token(for userId: String, config: ApiKeyConfig) -> String {
        if config == .oregon {
            if userId == "martin" {
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tanNAdjAuMC4wIiwic3ViIjoibWFydGluIiwiaWF0IjoxNjc1Njg0MTc5LCJ1c2VyX2lkIjoibWFydGluIn0.6kY4Ks5uW5aC12KttggDgXa38JwRRTyMPty7hdtG8e8"
            } else if userId == "oliver.lazoroski@getstream.io" {
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdHJlYW0tdmlkZW8tanNAdjAuMC4wIiwic3ViIjoidXNlci9vbGl2ZXIubGF6b3Jvc2tpQGdldHN0cmVhbS5pbyIsImlhdCI6MTY3NTY4NDE3OSwidXNlcl9pZCI6Im9saXZlci5sYXpvcm9za2lAZ2V0c3RyZWFtLmlvIn0._jJtu0ECQL73ohteU1fZFjcnLHb1m3SyyKabEMopS2A"
            }
        } else if config == .frankfurt {
            if userId == "martin" {
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwidXNlcl9pZCI6Im1hcnRpbiIsImlhdCI6MTUxNjIzOTAyMn0.Rgz8X6arOZduR03BuDFH-ji5yixtPrj5w7PKj1gNyMg"
            } else if userId == "oliver.lazoroski@getstream.io" {
                return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwidXNlcl9pZCI6Im9saXZlci5sYXpvcm9za2lAZ2V0c3RyZWFtLmlvIiwiaWF0IjoxNTE2MjM5MDIyfQ.qDNb4I_zygaWL_qgHyjV0dg2IiSmvNpuuU86F8eFy1s"
            }
        }
        return ""
    }

}
