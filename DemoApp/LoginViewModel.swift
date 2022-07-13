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
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published var loading = false
    
    @Published var userCredentials = [
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
    
    func login(user: UserCredentials) {
        Task {
            do {
                loading = true
                try await streamVideo.connectUser(userInfo: user.userInfo, token: user.token)
                loading = false
                AppState.shared.userState = .loggedIn
            } catch {
                loading = false
                log.error("Error occured: \(error.localizedDescription)")
            }
        }
    }
    
}

struct UserCredentials: Identifiable {
    var id: String {
        userInfo.id
    }
    let userInfo: UserInfo
    let token: Token
}
