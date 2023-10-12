//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

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

    enum BaseURL: String, Debuggable, CaseIterable {
        case staging = "https://staging.getstream.io"
        case pronto = "https://pronto.getstream.io"
        case production = "https://getstream.io"

        var url: URL { URL(string: rawValue)! }
        var title: String {
            switch self {
            case .staging:
                return "Staging"
            case .pronto:
                return "Pronto"
            case .production:
                return "Production"
            }
        }
    }

    static var baseURL: BaseURL = {
        switch configuration {
        case .test:
            return .staging
        case .debug:
            return .staging
        case .release:
            return .production
        }
    }()
}

extension AppEnvironment {

    enum APIKey: String {
        case staging = "hd8szvscpxvd"
        case production = "mmhfdzb5evj2"
    }

    static var apiKey: APIKey = {
        switch configuration {
        case .test:
            return APIKey.staging
        case .debug:
            return APIKey.staging
        case .release:
            return APIKey.production
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
        case universal = "https://stream-calls-dogfood.vercel.app"

        var url: URL { URL(string: rawValue)! }
    }

    static var authBaseURL: URL = { AuthBaseURL.universal.url }()
}

extension AppEnvironment {

    enum Argument: String {
        case mockJWT = "MOCK_JWT"
    }

    enum Variable: String {
        case JWTExpiration = "JWT_EXPIRATION"
        case googleClientId = "GOOGLE_CLIENT_ID"
        case googleReversedClientId = "REVERSED_GOOGLE_CLIENT_ID"
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
            return .simple
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

    enum SupportedDeeplink: Debuggable {
        case staging
        case pronto
        case production

        var deeplinkURL: URL {
            switch self {
            case .staging:
                return BaseURL.staging.url
            case .pronto:
                return BaseURL.pronto.url
            case .production:
                return BaseURL.production.url
            }
        }

        var title: String {
            switch self {
            case .staging:
                return "Staging"
            case .pronto:
                return "Pronto"
            case .production:
                return "Production"
            }
        }
    }

    static var supportedDeeplinks: [SupportedDeeplink] = {
        switch configuration {
        case .debug:
            return [.staging, .pronto, .production]
        case .test:
            return [.staging, .pronto, .production]
        case .release:
            return [.production]
        }
    }()
}
