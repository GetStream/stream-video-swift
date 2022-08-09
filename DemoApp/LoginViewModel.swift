//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

@MainActor
class LoginViewModel: ObservableObject {
        
    @Published var loading = false
    
    @Published var userCredentials = mockUsers
    
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

var mockUsers = [
    UserCredentials(
        userInfo: UserInfo(
            id: "alice",
            name: "Alice",
            imageURL: nil,
            extraData: [:]
        ),
        token: try! Token(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYWxpY2UifQ.p0_t4y5AU8T5Ib6qEvcKG6r2wduwt0n0SW6cD867SY8")
    ),
    UserCredentials(
        userInfo: UserInfo(
            id: "bob",
            name: "Bob",
            imageURL: nil,
            extraData: [:]
        ),
        token: try! Token(rawValue:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYm9iIn0.YZtLYNIPbxjvpzvWX4Vz3xXerTSbjcl4F3kFkC5sY3s")
    ),
    UserCredentials(
        userInfo: UserInfo(
            id: "trudy",
            name: "Trudy",
            imageURL: nil,
            extraData: [:]
        ),
        token: try! Token(rawValue:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidHJ1ZHkifQ.dcoph9LxfiGBkTCJjIyf7ENtGQInSsB-rt8-98Ll2UY")
    )
]
