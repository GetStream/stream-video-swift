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

protocol VoIPTokenHandler {

    func save(voIPPushToken: String?)

    func currentVoIPPushToken() -> String?

}

protocol PushTokenHandler {
    
    func save(pushToken: String?)
    
    func currentPushToken() -> String?
    
}

protocol RunConfigurationHandler {

    func save(configuration: AppEnvironment.Configuration)
    func currentConfiguration() -> AppEnvironment.Configuration?
}

//NOTE: This is just for simplicity. User data shouldn't be kept in `UserDefaults`.
final class UnsecureRepository: UserRepository, VoIPTokenHandler, PushTokenHandler, RunConfigurationHandler {
    enum Key: String, CaseIterable {
        case user = "stream.video.user"
        case token = "stream.video.token"
        case voIPPushToken = "stream.video.voip.token"
        case pushToken = "stream.video.push.token"
        case lastRunConfiguration = "stream.video.last.run.configuration"
        case lastRunBaseURL = "stream.video.last.run.baseURL"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }

    private func set(_ value: Any?, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    private func get<T>(for key: Key) -> T? {
        defaults.object(forKey: key.rawValue) as? T
    }

    func save(user: UserCredentials) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user.userInfo) {
            set(encoded, for: .user)
            save(token: user.token.rawValue)
        }
    }

    func save(token: String) { set(token, for: .token) }

    func loadCurrentUser() -> UserCredentials? {
        if let savedUser: Data = get(for: .user) {
            let decoder = JSONDecoder()
            do {
                let loadedUser = try decoder.decode(User.self, from: savedUser)
                guard let tokenValue: String = get(for: .token) else {
                    throw ClientError.Unexpected()
                }
                let token = UserToken(rawValue: tokenValue)
                return UserCredentials(userInfo: loadedUser, token: token)
            } catch {
                log.error("Error while decoding user", error: error)
            }
        }
        return nil
    }

    func save(voIPPushToken: String?) {
        set(voIPPushToken, for: .voIPPushToken)
    }

    func currentVoIPPushToken() -> String? {
        get(for: .voIPPushToken)
    }

    func currentPushToken() -> String? {
        get(for: .pushToken)
    }

    func save(pushToken: String?) {
        set(pushToken, for: .pushToken)
    }

    func removeCurrentUser() {
        defaults.set(nil, forKey: Key.user.rawValue)
        defaults.set(nil, forKey: Key.token.rawValue)
        defaults.set(nil, forKey: Key.voIPPushToken.rawValue)
        defaults.set(nil, forKey: Key.pushToken.rawValue)
    }

    func save(configuration: AppEnvironment.Configuration) {
        set(configuration.rawValue, for: .lastRunConfiguration)
    }

    func currentConfiguration() -> AppEnvironment.Configuration? {
        guard let lastConfigurationString: String = get(for: .lastRunConfiguration) else {
            return nil
        }
        return .init(rawValue: lastConfigurationString)
    }

    func save(baseURL: AppEnvironment.BaseURL) {
        set(baseURL.rawValue, for: .lastRunBaseURL)
    }

    func currentBaseURL() -> AppEnvironment.BaseURL? {
        guard let lastBaseURLString: String = get(for: .lastRunBaseURL) else {
            return nil
        }
        return .init(rawValue: lastBaseURLString)
    }
}
