//
//  LoginViewModel.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.7.22.
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
        token: try! Token(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYWxpY2UifQ.WZkPaUZb84fLkQoEEFw078Xd1RzwR42XjvBISgM2BAk")
    ),
    UserCredentials(
        userInfo: UserInfo(
            id: "bob",
            name: "Bob",
            imageURL: nil,
            extraData: [:]
        ),
        token: try! Token(rawValue:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYm9iIn0.6fqa74FESB2DMUcsIiArBDJR2ckkdSvWiSb7qRLVU6U")
    ),
    UserCredentials(
        userInfo: UserInfo(
            id: "trudy",
            name: "Trudy",
            imageURL: nil,
            extraData: [:]
        ),
        token: try! Token(rawValue:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidHJ1ZHkifQ.yhwq7Dv7znpFiIZrAb9bOYiEXM_PHtgqoq5pgFeOL78")
    )
]
