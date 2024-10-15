//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

protocol Debuggable: Hashable {
    var title: String { get }
}

enum AppEnvironment {}

extension AppEnvironment {

    enum Configuration: String, Hashable, Codable {
        case debug, test, release
        
        var isDebug: Bool { self == .debug }
        var isRelease: Bool { self == .release }
        var isTest: Bool { self == .test }
    }

    static var configuration: Configuration = {
        #if STREAM_RELEASE
        return .release
        #elseif STREAM_E2E_TESTS
        return .test
        #else
        return .debug
        #endif
    }()
}

extension AppEnvironment {

    indirect enum BaseURL: Debuggable, CaseIterable {
        case pronto
        case prontoStaging
        case staging
        case demo
        case legacy
        case custom(baseURL: BaseURL, apiKey: String, token: String)

        var url: URL {
            switch self {
            case .pronto:
                URL(string: "https://pronto.getstream.io")!
            case .prontoStaging:
                URL(string: "https://pronto-staging.getstream.io")!
            case .staging:
                URL(string: "https://staging.getstream.io")!
            case .demo:
                URL(string: "https://getstream.io")!
            case .legacy:
                URL(string: "https://stream-calls-dogfood.vercel.app")!
            case let .custom(baseURL, _, _):
                baseURL.url
            }
        }

        var title: String {
            switch self {
            case .pronto:
                return "Pronto"
            case .prontoStaging:
                return "Pronto Staging"
            case .staging:
                return "Staging"
            case .legacy:
                return "Legacy"
            case .demo:
                return "Demo"
            case let .custom(_, apiKey, _):
                return apiKey.isEmpty ? "Custom" : "Custom(\(apiKey)"
            }
        }

        var identifier: String {
            switch self {
            case .pronto:
                return "pronto"
            case .prontoStaging:
                return "pronto-staging"
            case .staging:
                return "staging"
            case .legacy:
                return "legacy"
            case .demo:
                return "demo"
            case let .custom:
                return "custom"
            }
        }

        func joinLink(
            _ callId: String,
            callType: String = .default,
            apiKey: String? = nil,
            userId: String? = nil,
            token: String? = nil
        ) -> URL {
            switch self {
            case .demo:
                return url
                    .appendingPathComponent("video")
                    .appendingPathComponent("demos")
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
                    .addQueryParameter("api_key", value: apiKey)
                    .addQueryParameter("user_id", value: userId)
                    .addQueryParameter("token", value: token)
            case let .custom(baseURL, _, _):
                return baseURL
                    .url
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
                    .addQueryParameter("api_key", value: apiKey)
                    .addQueryParameter("user_id", value: userId)
                    .addQueryParameter("token", value: token)
            default:
                return url
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
                    .addQueryParameter("api_key", value: apiKey)
                    .addQueryParameter("user_id", value: userId)
                    .addQueryParameter("token", value: token)
            }
        }

        static var allCases: [BaseURL] = [
            .pronto,
            .prontoStaging,
            .staging,
            .demo,
            .legacy
        ]
    }

    static var baseURL: BaseURL = {
        switch configuration {
        case .test:
            return .demo
        case .debug:
            return .pronto
        case .release:
            return .demo
        }
    }()
}

extension AppEnvironment {

    enum AppURLScheme: String {
        case universal = "streamvideo"
    }

    static var appURLScheme: String = { AppURLScheme.universal.rawValue }()
}

extension AppEnvironment {

    enum AuthBaseURL: String {
        case universal = "https://pronto.getstream.io/api/auth/create-token"

        var url: URL { URL(string: rawValue)! }
    }

    static var authBaseURL: URL = { AuthBaseURL.universal.url }()
}

extension AppEnvironment {

    enum InfoPlistValue: String {
        case googleClientId = "GOOGLE_CLIENT_ID"
        case googleReversedClientId = "REVERSED_GOOGLE_CLIENT_ID"
    }

    enum Argument: String {
        case mockJWT = "MOCK_JWT"
        case invalidateJWT = "INVALIDATE_JWT"
        case breakJWT = "BREAK_JWT"
    }

    enum Variable: String {
        case JWTExpiration = "JWT_EXPIRATION"
    }

    static func contains(_ argument: Argument) -> Bool {
        ProcessInfo
            .processInfo
            .arguments
            .contains(argument.rawValue)
    }

    static func value(for variable: Variable) -> String? {
        ProcessInfo
            .processInfo
            .environment[variable.rawValue]
    }

    static func value<T>(for variable: InfoPlistValue) -> T? {
        Bundle
            .main
            .infoDictionary?[variable.rawValue] as? T
    }
}

extension AppEnvironment {

    enum LoggedInView: Hashable, Debuggable {
        case simple, detailed

        var title: String {
            switch self {
            case .simple:
                return "Simple"
            case .detailed:
                return "Detailed"
            }
        }
    }

    static var loggedInView: LoggedInView = {
        switch configuration {
        case .test:
            return .detailed
        case .debug:
            #if targetEnvironment(simulator)
            return .simple
            #else
            return .simple
            #endif
        case .release:
            return .simple
        }
    }()
}

extension AppEnvironment {

    enum PerformanceTrackerVisibility: Hashable, Debuggable {
        case visible, hidden

        var title: String {
            switch self {
            case .visible:
                return "Visible"
            case .hidden:
                return "Hidden"
            }
        }
    }

    static var performanceTrackerVisibility: PerformanceTrackerVisibility = {
        .hidden
    }()
}

extension AppEnvironment {

    enum ChatIntegration: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                return "Enabled"
            case .disabled:
                return "Disabled"
            }
        }
    }

    static var chatIntegration: ChatIntegration = {
        .enabled
    }()
}

extension AppEnvironment {

    enum SupportedDeeplink: Debuggable, CaseIterable {
        case pronto
        case prontoStaging
        case staging
        case demo
        case legacy

        var deeplinkURL: URL {
            switch self {
            case .pronto:
                return BaseURL.pronto.url
            case .prontoStaging:
                return BaseURL.prontoStaging.url
            case .staging:
                return BaseURL.staging.url
            case .demo:
                return BaseURL.demo.url
            case .legacy:
                return BaseURL.legacy.url
            }
        }

        var title: String {
            switch self {
            case .pronto:
                return "Pronto"
            case .prontoStaging:
                return "Pronto Staging"
            case .staging:
                return "Staging"
            case .demo:
                return "Demo"
            case .legacy:
                return "Legacy"
            }
        }
    }

    static var supportedDeeplinks: [SupportedDeeplink] = {
        switch configuration {
        case .debug:
            return [.pronto, .prontoStaging, .demo, .staging, .legacy]
        case .test:
            return [.pronto, .prontoStaging, .demo, .staging, .legacy]
        case .release:
            return [.demo]
        }
    }()
}

extension AppEnvironment {

    enum PictureInPictureIntegration: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                return "Enabled"
            case .disabled:
                return "Disabled"
            }
        }
    }

    static var pictureInPictureIntegration: PictureInPictureIntegration = {
        .enabled
    }()
}

extension AppEnvironment {

    enum TokenExpiration: Hashable, Debuggable {
        case never
        case oneMinute
        case fiveMinutes
        case tenMinutes
        case thirtyMinutes
        case custom(Int)

        var title: String {
            switch self {
            case .never:
                return "Never"
            case .oneMinute:
                return "1'"
            case .fiveMinutes:
                return "5'"
            case .tenMinutes:
                return "10'"
            case .thirtyMinutes:
                return "30'"
            case let .custom(value):
                return "\(value)\""
            }
        }

        var interval: Int {
            switch self {
            case .never:
                return 0
            case .oneMinute:
                return 1 * 60
            case .fiveMinutes:
                return 5 * 60
            case .tenMinutes:
                return 10 * 60
            case .thirtyMinutes:
                return 30 * 60
            case let .custom(value):
                return value
            }
        }
    }

    static var tokenExpiration: TokenExpiration = {
        switch configuration {
        case .debug:
            return .never
        case .test:
            return .oneMinute
        case .release:
            return .thirtyMinutes
        }
    }()
}

extension AppEnvironment {

    enum CallExpiration: Hashable, Debuggable {
        case never
        case twoMinutes
        case fiveMinutes
        case tenMinutes
        case custom(Int)

        var title: String {
            switch self {
            case .never:
                return "Never"
            case .twoMinutes:
                return "2'"
            case .fiveMinutes:
                return "5'"
            case .tenMinutes:
                return "10'"
            case let .custom(value):
                return "\(value)\""
            }
        }

        var duration: Int? {
            switch self {
            case .never:
                return nil
            case .twoMinutes:
                return 2 * 60
            case .fiveMinutes:
                return 5 * 60
            case .tenMinutes:
                return 10 * 60
            case let .custom(value):
                return value
            }
        }
    }

    static var callExpiration: CallExpiration = .never
}

extension AppEnvironment {

    enum AutoLeavePolicy: Hashable, Debuggable {
        case `default`
        case lastParticipant

        var title: String {
            switch self {
            case .default:
                return "Default"
            case .lastParticipant:
                return "Last Participant"
            }
        }

        var policy: ParticipantAutoLeavePolicy {
            switch self {
            case .default:
                DefaultParticipantAutoLeavePolicy()
            case .lastParticipant:
                LastParticipantAutoLeavePolicy()
            }
        }
    }

    static var autoLeavePolicy: AutoLeavePolicy = .default
}
