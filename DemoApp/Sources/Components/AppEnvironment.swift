//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        case prontoFrankfurtC2
        case livestream
        case custom(baseURL: BaseURL, apiKey: String, token: String)

        var url: URL {
            switch self {
            case .pronto:
                URL(string: "https://pronto.getstream.io")!
            case .prontoStaging:
                URL(string: "https://pronto-staging.getstream.io")!
            case .staging, .prontoFrankfurtC2:
                URL(string: "https://staging.getstream.io")!
            case .demo:
                URL(string: "https://getstream.io")!
            case .legacy:
                URL(string: "https://stream-calls-dogfood.vercel.app")!
            case .livestream:
                URL(string: "https://livestream-react-demo.vercel.app")!
            case let .custom(baseURL, _, _):
                baseURL.url
            }
        }

        var title: String {
            switch self {
            case .pronto:
                "Pronto"
            case .prontoStaging:
                "Pronto Staging"
            case .prontoFrankfurtC2:
                "Pronto Staging C2"
            case .staging:
                "Staging"
            case .legacy:
                "Legacy"
            case .livestream:
                "Livestream"
            case .demo:
                "Demo"
            case let .custom(_, apiKey, _):
                apiKey.isEmpty ? "Custom" : "Custom(\(apiKey)"
            }
        }

        func joinLink(_ callId: String, callType: String = .default) -> URL {
            switch self {
            case .demo:
                url
                    .appendingPathComponent("video")
                    .appendingPathComponent("demos")
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
            case let .custom(baseURL, _, _):
                baseURL
                    .url
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
            case .livestream:
                url
                    .appending(.init(name: "id", value: callId))
            default:
                url
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
            }
        }

        static var allCases: [BaseURL] = [
            .pronto,
            .prontoStaging,
            .staging,
            .demo,
            .legacy,
            .livestream
        ]
    }

    static var baseURL: BaseURL = switch configuration {
    case .test:
        .demo
    case .debug:
        .pronto
    case .release:
        .demo
    }
}

extension AppEnvironment {

    enum AppURLScheme: String {
        case universal = "streamvideo"
    }

    static var appURLScheme: String = AppURLScheme.universal.rawValue
}

extension AppEnvironment {

    enum AuthBaseURL: String {
        case universal = "https://pronto.getstream.io/api/auth/create-token"

        var url: URL { URL(string: rawValue)! }
    }

    static var authBaseURL: URL = AuthBaseURL.universal.url
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
                "Simple"
            case .detailed:
                "Detailed"
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
                "Visible"
            case .hidden:
                "Hidden"
            }
        }
    }

    static var performanceTrackerVisibility: PerformanceTrackerVisibility = .hidden
}

extension AppEnvironment {

    enum ChatIntegration: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                "Enabled"
            case .disabled:
                "Disabled"
            }
        }
    }

    static var chatIntegration: ChatIntegration = .enabled
}

extension AppEnvironment {

    enum SupportedDeeplink: Debuggable, CaseIterable {
        case pronto
        case staging
        case demo
        case legacy
        case livestream

        var deeplinkURL: URL {
            switch self {
            case .pronto:
                BaseURL.pronto.url
            case .staging:
                BaseURL.staging.url
            case .demo:
                BaseURL.demo.url
            case .legacy:
                BaseURL.legacy.url
            case .livestream:
                BaseURL.livestream.url
            }
        }

        var title: String {
            switch self {
            case .pronto:
                "Pronto"
            case .staging:
                "Staging"
            case .demo:
                "Demo"
            case .legacy:
                "Legacy"
            case .livestream:
                "Livestream"
            }
        }
    }

    static var supportedDeeplinks: [SupportedDeeplink] = switch configuration {
    case .debug:
        [.pronto, .demo, .staging, .legacy, .livestream]
    case .test:
        [.pronto, .demo, .staging, .legacy]
    case .release:
        [.demo, .livestream]
    }
}

extension AppEnvironment {

    enum PictureInPictureIntegration: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                "Enabled"
            case .disabled:
                "Disabled"
            }
        }
    }

    static var pictureInPictureIntegration: PictureInPictureIntegration = .enabled
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
                "Never"
            case .oneMinute:
                "1'"
            case .fiveMinutes:
                "5'"
            case .tenMinutes:
                "10'"
            case .thirtyMinutes:
                "30'"
            case let .custom(value):
                "\(value)\""
            }
        }

        var interval: Int {
            switch self {
            case .never:
                0
            case .oneMinute:
                1 * 60
            case .fiveMinutes:
                5 * 60
            case .tenMinutes:
                10 * 60
            case .thirtyMinutes:
                30 * 60
            case let .custom(value):
                value
            }
        }
    }

    static var tokenExpiration: TokenExpiration = switch configuration {
    case .debug:
        .never
    case .test:
        .oneMinute
    case .release:
        .thirtyMinutes
    }
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
                "Never"
            case .twoMinutes:
                "2'"
            case .fiveMinutes:
                "5'"
            case .tenMinutes:
                "10'"
            case let .custom(value):
                "\(value)\""
            }
        }

        var duration: Int? {
            switch self {
            case .never:
                nil
            case .twoMinutes:
                2 * 60
            case .fiveMinutes:
                5 * 60
            case .tenMinutes:
                10 * 60
            case let .custom(value):
                value
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
                "Default"
            case .lastParticipant:
                "Last Participant"
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

extension AppEnvironment {

    enum DisconnectionTimeout: Hashable, Debuggable {
        case never
        case twoMinutes
        case custom(TimeInterval)

        var title: String {
            switch self {
            case .never:
                "Never"
            case .twoMinutes:
                "2'"
            case let .custom(value):
                "\(value)\""
            }
        }

        var duration: TimeInterval {
            switch self {
            case .never:
                0
            case .twoMinutes:
                2 * 60
            case let .custom(value):
                value
            }
        }
    }

    static var disconnectionTimeout: DisconnectionTimeout = .never
}

extension AppEnvironment {

    enum PreferredVideoCodec: Hashable, Debuggable {
        case h264
        case vp8
        case vp9
        case av1

        var title: String {
            switch self {
            case .h264:
                "h264"
            case .vp8:
                "VP8"
            case .vp9:
                "VP9"
            case .av1:
                "AV1"
            }
        }

        var videoCodec: VideoCodec {
            switch self {
            case .h264:
                .h264
            case .vp8:
                .vp8
            case .vp9:
                .vp9
            case .av1:
                .av1
            }
        }
    }

    static var preferredVideoCodec: PreferredVideoCodec = .h264
}

extension AppEnvironment {

    enum ClosedCaptionsIntegration: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                "Enabled"
            case .disabled:
                "Disabled"
            }
        }
    }

    static var closedCaptionsIntegration: ClosedCaptionsIntegration = .disabled
}

extension AppEnvironment {

    enum AudioSessionPolicyDebugConfiguration: Hashable, Debuggable, Sendable {
        case `default`, ownCapabilities

        var title: String {
            switch self {
            case .default:
                "Default"
            case .ownCapabilities:
                "OwnCapabilities"
            }
        }

        var value: AudioSessionPolicy {
            switch self {
            case .default:
                DefaultAudioSessionPolicy()
            case .ownCapabilities:
                OwnCapabilitiesAudioSessionPolicy()
            }
        }
    }

    static var audioSessionPolicy: AudioSessionPolicyDebugConfiguration = .default
}

extension AppEnvironment {

    static var availableCallTypes: [String] = [
        .development,
        .default,
        .audioRoom,
        .livestream
    ]
    static var preferredCallType: String?
}

extension AppEnvironment {

    enum ProximityPolicyDebugConfiguration: Hashable, Debuggable, Sendable, CaseIterable {
        case speaker, video

        var title: String {
            switch self {
            case .speaker:
                "Speaker"
            case .video:
                "Video"
            }
        }

        var value: ProximityPolicy {
            switch self {
            case .speaker:
                SpeakerProximityPolicy()
            case .video:
                VideoProximityPolicy()
            }
        }
    }

    static var proximityPolicies: Set<ProximityPolicyDebugConfiguration> = [.speaker, .video]
}

extension String: Debuggable {
    var title: String {
        self
    }
}
