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
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjQyLCJjYWxsX2lkIjoiY2FsbDoxMjMiLCJ1c2VyIjp7ImlkIjoidG9tbWFzbyIsImltYWdlX3VybCI6Imh0dHBzOi8vZ2V0c3RyZWFtLmlvL3N0YXRpYy83MTJiYjVjMGJkNWVkOGQzZmE2ZTU4NDJmNmNmYmVlZC9jNTlkZS90b21tYXNvLndlYnAifSwiZ3JhbnRzIjp7ImNhbl9qb2luX2NhbGwiOnRydWUsImNhbl9wdWJsaXNoX3ZpZGVvIjp0cnVlLCJjYW5fcHVibGlzaF9hdWRpbyI6dHJ1ZSwiY2FuX3NjcmVlbl9zaGFyZSI6dHJ1ZSwiY2FuX211dGVfdmlkZW8iOnRydWUsImNhbl9tdXRlX2F1ZGlvIjp0cnVlfSwiaXNzIjoiZGV2LW9ubHkucHVia2V5LmVjZHNhMjU2IiwiYXVkIjpbImxvY2FsaG9zdCJdfQ.5EFD_nsXygyQxztBSqoPg_muPHOk5xSEmnfbyHl63o8mZ5xLqT8DLFrimKVGupsh2y7h0wPu59lDk7wkfulEdg"
        ),
        (
            "marcelo",
            "Marcelo",
            "https://getstream.io/static/aaf5fb17dcfd0a3dd885f62bd21b325a/802d2/marcelo-pires.webp",
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjQyLCJjYWxsX2lkIjoiY2FsbDoxMjMiLCJ1c2VyIjp7ImlkIjoibWFyY2VsbyIsImltYWdlX3VybCI6Imh0dHBzOi8vZ2V0c3RyZWFtLmlvL3N0YXRpYy9hYWY1ZmIxN2RjZmQwYTNkZDg4NWY2MmJkMjFiMzI1YS84MDJkMi9tYXJjZWxvLXBpcmVzLndlYnAifSwiZ3JhbnRzIjp7ImNhbl9qb2luX2NhbGwiOnRydWUsImNhbl9wdWJsaXNoX3ZpZGVvIjp0cnVlLCJjYW5fcHVibGlzaF9hdWRpbyI6dHJ1ZSwiY2FuX3NjcmVlbl9zaGFyZSI6dHJ1ZSwiY2FuX211dGVfdmlkZW8iOnRydWUsImNhbl9tdXRlX2F1ZGlvIjp0cnVlfSwiaXNzIjoiZGV2LW9ubHkucHVia2V5LmVjZHNhMjU2IiwiYXVkIjpbImxvY2FsaG9zdCJdfQ.iS3xIPX_jAsjyiZbrNkcFkpbzF1ocQGmS6qFiYlfYWnez56bsNEJ0_YTkowdyZfdlB_9u36PGnreaqoBigbZpg"
        ),
        (
            "martin",
            "Martin",
            "https://getstream.io/static/2796a305dd07651fcceb4721a94f4505/802d2/martin-mitrevski.webp",
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjQyLCJjYWxsX2lkIjoiY2FsbDoxMjMiLCJ1c2VyIjp7ImlkIjoibWFydGluIiwiaW1hZ2VfdXJsIjoiaHR0cHM6Ly9nZXRzdHJlYW0uaW8vc3RhdGljLzI3OTZhMzA1ZGQwNzY1MWZjY2ViNDcyMWE5NGY0NTA1LzgwMmQyL21hcnRpbi1taXRyZXZza2kud2VicCJ9LCJncmFudHMiOnsiY2FuX2pvaW5fY2FsbCI6dHJ1ZSwiY2FuX3B1Ymxpc2hfdmlkZW8iOnRydWUsImNhbl9wdWJsaXNoX2F1ZGlvIjp0cnVlLCJjYW5fc2NyZWVuX3NoYXJlIjp0cnVlLCJjYW5fbXV0ZV92aWRlbyI6dHJ1ZSwiY2FuX211dGVfYXVkaW8iOnRydWV9LCJpc3MiOiJkZXYtb25seS5wdWJrZXkuZWNkc2EyNTYiLCJhdWQiOlsibG9jYWxob3N0Il19.9mHCY3tF4qFYbNcWaHoF0Azs9-r7mNdgefxdw3B56m_27nqLZYgjcyVG9Tqv3LT_5L766FE6tPIZ_ZQ1-_ONwA"
        ),
        (
            "filip",
            "Filip",
            "https://getstream.io/static/76cda49669be38b92306cfc93ca742f1/802d2/filip-babi%C4%87.webp",
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjQyLCJjYWxsX2lkIjoiY2FsbDoxMjMiLCJ1c2VyIjp7ImlkIjoiZmlsaXAiLCJpbWFnZV91cmwiOiJodHRwczovL2dldHN0cmVhbS5pby9zdGF0aWMvNzZjZGE0OTY2OWJlMzhiOTIzMDZjZmM5M2NhNzQyZjEvODAyZDIvZmlsaXAtYmFiaSVDNCU4Ny53ZWJwIn0sImdyYW50cyI6eyJjYW5fam9pbl9jYWxsIjp0cnVlLCJjYW5fcHVibGlzaF92aWRlbyI6dHJ1ZSwiY2FuX3B1Ymxpc2hfYXVkaW8iOnRydWUsImNhbl9zY3JlZW5fc2hhcmUiOnRydWUsImNhbl9tdXRlX3ZpZGVvIjp0cnVlLCJjYW5fbXV0ZV9hdWRpbyI6dHJ1ZX0sImlzcyI6ImRldi1vbmx5LnB1YmtleS5lY2RzYTI1NiIsImF1ZCI6WyJsb2NhbGhvc3QiXX0.XmvDAtIAjnWMETVun0Vffcrp9Tk7xujXZS8GawVdBY8R8yxec4asziTUKHJCkXq6GjeJtEVMtrzoJs9qP0xtDQ"
        ),
        (
            "thierry",
            "Thierry",
            "https://getstream.io/static/237f45f28690696ad8fff92726f45106/c59de/thierry.webp",
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjQyLCJjYWxsX2lkIjoiY2FsbDoxMjMiLCJ1c2VyIjp7ImlkIjoidGhpZXJyeSIsImltYWdlX3VybCI6Imh0dHBzOi8vZ2V0c3RyZWFtLmlvL3N0YXRpYy8yMzdmNDVmMjg2OTA2OTZhZDhmZmY5MjcyNmY0NTEwNi9jNTlkZS90aGllcnJ5LndlYnAifSwiZ3JhbnRzIjp7ImNhbl9qb2luX2NhbGwiOnRydWUsImNhbl9wdWJsaXNoX3ZpZGVvIjp0cnVlLCJjYW5fcHVibGlzaF9hdWRpbyI6dHJ1ZSwiY2FuX3NjcmVlbl9zaGFyZSI6dHJ1ZSwiY2FuX211dGVfdmlkZW8iOnRydWUsImNhbl9tdXRlX2F1ZGlvIjp0cnVlfSwiaXNzIjoiZGV2LW9ubHkucHVia2V5LmVjZHNhMjU2IiwiYXVkIjpbImxvY2FsaG9zdCJdfQ.pmaz5REWBAWLSJsycIkKcpJlCPr9eyUCB4Pa3ij5Mt5yai39ZZC8zsweR_mKlP-yYo4Zb69zfodA3PWwRhEUCg"
        ),
        (
            "sam",
            "Sam",
            "https://getstream.io/static/379eda22663bae101892ad1d37778c3d/802d2/samuel-jeeves.webp",
            "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfaWQiOjQyLCJjYWxsX2lkIjoiY2FsbDoxMjMiLCJ1c2VyIjp7ImlkIjoic2FtIiwiaW1hZ2VfdXJsIjoiaHR0cHM6Ly9nZXRzdHJlYW0uaW8vc3RhdGljLzM3OWVkYTIyNjYzYmFlMTAxODkyYWQxZDM3Nzc4YzNkLzgwMmQyL3NhbXVlbC1qZWV2ZXMud2VicCJ9LCJncmFudHMiOnsiY2FuX2pvaW5fY2FsbCI6dHJ1ZSwiY2FuX3B1Ymxpc2hfdmlkZW8iOnRydWUsImNhbl9wdWJsaXNoX2F1ZGlvIjp0cnVlLCJjYW5fc2NyZWVuX3NoYXJlIjp0cnVlLCJjYW5fbXV0ZV92aWRlbyI6dHJ1ZSwiY2FuX211dGVfYXVkaW8iOnRydWV9LCJpc3MiOiJkZXYtb25seS5wdWJrZXkuZWNkc2EyNTYiLCJhdWQiOlsibG9jYWxob3N0Il19.Qxta03Hncph0yoYy3hMxUc3dEhUjxckoRXo8VT-IefY6Lm3d7UUQDwld1zcpTz73GezmPLYKqo0oWsHZFOMVow"
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
