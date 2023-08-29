//
//  UserCredentials.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import StreamVideo

struct UserCredentials: Identifiable, Codable {
    var id: String {
        userInfo.id
    }
    let userInfo: User
    let token: UserToken
}
