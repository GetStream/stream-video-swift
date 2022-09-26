//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

protocol UserRepository {
    
    func save(user: UserCredentials)
    
    func loadCurrentUser() -> UserCredentials?
    
    func removeCurrentUser()
    
}

//NOTE: This is just for simplicity. User data shouldn't be kept in `UserDefaults`.
class UnsecureUserRepository: UserRepository {
    
    private let defaults = UserDefaults.standard
    private let userKey = "stream.video.user"
    private let tokenKey = "stream.video.token"
    
    static let shared = UnsecureUserRepository()
    
    private init() {}
    
    func save(user: UserCredentials) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user.userInfo) {
            defaults.set(encoded, forKey: userKey)
            defaults.set(user.token.rawValue, forKey: tokenKey)
        }
    }
    
    func loadCurrentUser() -> UserCredentials? {
        if let savedUser = defaults.object(forKey: userKey) as? Data {
            let decoder = JSONDecoder()
            do {
                let loadedUser = try decoder.decode(UserInfo.self, from: savedUser)
                guard let tokenValue = defaults.value(forKey: tokenKey) as? String else {
                    throw ClientError.Unexpected()
                }
                let token = try Token(rawValue: tokenValue)
                return UserCredentials(userInfo: loadedUser, token: token)
            } catch {
                log.error("Error while decoding user: \(String(describing: error))")
            }
        }
        return nil
    }
    
    func removeCurrentUser() {
        defaults.set(nil, forKey: userKey)
        defaults.set(nil, forKey: tokenKey)
    }
    
    
}
