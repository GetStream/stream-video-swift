//
//  Environment.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation

enum AppEnvironment {}

extension AppEnvironment {

    enum Configuration: String, Hashable, Codable {
        case debug, test, release
        
        var isDebug: Bool { self == .debug }
        var isRelease: Bool { self == .release }
        var isTest: Bool { self == .test }
    }

    static var configuration: Configuration {
#if STREAM_RELEASE
        return .release
#elseif STREAM_E2E_TESTS
        return .test
#else
        return .debug
#endif
    }
}

extension AppEnvironment {

    enum BaseURL: String {
        case staging = "https://staging.getstream.io"
        case production = "https://getstream.io"

        var url: URL { URL(string: rawValue)! }
    }

    static var baseURL: BaseURL {
#if STREAM_RELEASE
        return .production
#elseif STREAM_E2E_TESTS
        return .staging
#else
        return .staging
#endif
    }
}

extension AppEnvironment {

    enum APIKey: String {
        case staging = "hd8szvscpxvd"
        case production = "mmhfdzb5evj2"
    }

    static var apiKey: String {
#if STREAM_RELEASE
        return APIKey.production.rawValue
#elseif STREAM_E2E_TESTS
        return APIKey.staging.rawValue
#else
        return APIKey.staging.rawValue
#endif
    }
}

extension AppEnvironment {

    enum AppURLScheme: String {
        case universal = "streamvideo"
    }

    static var appURLScheme: String { AppURLScheme.universal.rawValue }
}


extension AppEnvironment {

    enum AuthBaseURL: String {
        case universal = "https://stream-calls-dogfood.vercel.app"

        var url: URL { URL(string: rawValue)! }
    }

    static var authBaseURL: URL { AuthBaseURL.universal.url }
}

extension AppEnvironment {

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
}
