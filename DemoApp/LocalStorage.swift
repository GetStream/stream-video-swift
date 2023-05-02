//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

protocol UserRepository {
    
    func save(user: UserCredentials)
    
    func save(token: String)
    
    func loadCurrentUser() -> UserCredentials?
    
    func removeCurrentUser()
    
}

protocol VoipTokenHandler {
    
    func save(voipPushToken: String?)
    
    func currentVoipPushToken() -> String?
    
}

protocol PushTokenHandler {
    
    func save(pushToken: String?)
    
    func currentPushToken() -> String?
    
}

//NOTE: This is just for simplicity. User data shouldn't be kept in `UserDefaults`.
class UnsecureUserRepository: UserRepository, VoipTokenHandler, PushTokenHandler {
    private let defaults = UserDefaults.standard
    private let userKey = "stream.video.user"
    private let tokenKey = "stream.video.token"
    private let voipPushTokenKey = "stream.video.voip.token"
    private let pushTokenKey = "stream.video.push.token"
    
    static let shared = UnsecureUserRepository()
    
    private init() {}
    
    func save(user: UserCredentials) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user.userInfo) {
            defaults.set(encoded, forKey: userKey)
            save(token: user.token.rawValue)
        }
    }
    
    func save(token: String) {
        defaults.set(token, forKey: tokenKey)
    }
    
    func loadCurrentUser() -> UserCredentials? {
        if let savedUser = defaults.object(forKey: userKey) as? Data {
            let decoder = JSONDecoder()
            do {
                let loadedUser = try decoder.decode(User.self, from: savedUser)
                guard let tokenValue = defaults.value(forKey: tokenKey) as? String else {
                    throw ClientError.Unexpected()
                }
                let token = try UserToken(rawValue: tokenValue)
                return UserCredentials(userInfo: loadedUser, token: token)
            } catch {
                log.error("Error while decoding user: \(String(describing: error))")
            }
        }
        return nil
    }
    
    func save(voipPushToken: String?) {
        defaults.set(voipPushToken, forKey: voipPushTokenKey)
    }
    
    func currentVoipPushToken() -> String? {
        defaults.value(forKey: voipPushTokenKey) as? String
    }
    
    func currentPushToken() -> String? {
        defaults.value(forKey: pushTokenKey) as? String
    }
    
    func save(pushToken: String?) {
        defaults.set(pushToken, forKey: pushTokenKey)
    }
    
    func removeCurrentUser() {
        defaults.set(nil, forKey: userKey)
        defaults.set(nil, forKey: tokenKey)
        defaults.set(nil, forKey: voipPushTokenKey)
        defaults.set(nil, forKey: pushTokenKey)
    }
    
    
}
