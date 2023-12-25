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
        case pronto = "https://pronto.getstream.io"
        case staging = "https://staging.getstream.io"
        case demo = "https://getstream.io"
        case legacy = "https://stream-calls-dogfood.vercel.app"

        var url: URL { URL(string: rawValue)! }
        var title: String {
            switch self {
            case .pronto:
                return "Pronto"
            case .staging:
                return "Staging"
            case .legacy:
                return "Legacy"
            case .demo:
                return "Demo"
            }
        }
    }

    static var baseURL: BaseURL = {
        switch configuration {
        case .test:
            return .pronto
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

    enum SupportedDeeplink: Debuggable, CaseIterable {
        case pronto
        case staging
        case demo
        case legacy

        var deeplinkURL: URL {
            switch self {
            case .pronto:
                return BaseURL.pronto.url
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
            return [.pronto, .demo, .staging, .legacy]
        case .test:
            return [.pronto, .demo, .staging, .legacy]
        case .release:
            return [.demo]
        }
    }()
}
