//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

protocol UserRepository {
    
    func save(user: UserCredentials)
    
    func loadCurrentUser() -> UserCredentials?
    
    func removeCurrentUser()
    
    func userFavorites() -> [String]
    
    func addToFavorites(userId: String)
    
    func removeFromFavorites(userId: String)
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

// NOTE: This is just for simplicity. User data shouldn't be kept in `UserDefaults`.
final class UnsecureRepository: UserRepository, VoIPTokenHandler, PushTokenHandler, RunConfigurationHandler {
    enum Key: String, CaseIterable {
        case user = "stream.video.user"
        case token = "stream.video.token"
        case voIPPushToken = "stream.video.voip.token"
        case pushToken = "stream.video.push.token"
        case lastRunConfiguration = "stream.video.last.run.configuration"
        case lastRunBaseURL = "stream.video.last.run.baseURL"
        case userFavorites = "stream.video.favorites"
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
        }
    }

    func loadCurrentUser() -> UserCredentials? {
        if let savedUser: Data = get(for: .user) {
            let decoder = JSONDecoder()
            do {
                let loadedUser = try decoder.decode(User.self, from: savedUser)
                return UserCredentials(userInfo: loadedUser, token: "") // The token will always get updated
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
        defaults.set(nil, forKey: Key.userFavorites.rawValue)
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
        set(baseURL.url.absoluteString, for: .lastRunBaseURL)
    }

    func currentBaseURL() -> AppEnvironment.BaseURL? {
        guard let lastBaseURLString: String = get(for: .lastRunBaseURL) else {
            return nil
        }
        if lastBaseURLString == AppEnvironment.BaseURL.demo.url.absoluteString {
            return .demo
        } else if lastBaseURLString == AppEnvironment.BaseURL.pronto.url.absoluteString {
            return .pronto
        } else if lastBaseURLString == AppEnvironment.BaseURL.legacy.url.absoluteString {
            return .legacy
        } else if lastBaseURLString == AppEnvironment.BaseURL.staging.url.absoluteString {
            return .staging
        } else {
            return .demo
        }
    }
    
    func userFavorites() -> [String] {
        get(for: .userFavorites) ?? [String]()
    }
    
    func addToFavorites(userId: String) {
        var favorites = userFavorites()
        if !favorites.contains(userId) {
            favorites.append(userId)
            set(favorites, for: .userFavorites)
        }
    }
    
    func removeFromFavorites(userId: String) {
        var favorites = userFavorites()
        favorites.removeAll { id in
            id == userId
        }
        set(favorites, for: .userFavorites)
    }
}
