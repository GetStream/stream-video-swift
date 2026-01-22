//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    nonisolated(unsafe) static var configuration: Configuration = {
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
                return "Pronto"
            case .prontoStaging:
                return "Pronto Staging"
            case .prontoFrankfurtC2:
                return "Pronto Staging C2"
            case .staging:
                return "Staging"
            case .legacy:
                return "Legacy"
            case .livestream:
                return "Livestream"
            case .demo:
                return "Demo"
            case let .custom(_, apiKey, _):
                return apiKey.isEmpty ? "Custom" : "Custom(\(apiKey)"
            }
        }

        func joinLink(_ callId: String, callType: String = .default) -> URL {
            switch self {
            case .demo:
                return url
                    .appendingPathComponent("video")
                    .appendingPathComponent("demos")
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
            case let .custom(baseURL, _, _):
                return baseURL
                    .url
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
            case .livestream:
                return url
                    .appending(.init(name: "id", value: callId))
            default:
                return url
                    .appendingPathComponent("join")
                    .appendingPathComponent(callId)
                    .addQueryParameter("type", value: callType)
            }
        }

        nonisolated(unsafe) static var allCases: [BaseURL] = [
            .pronto,
            .prontoStaging,
            .staging,
            .demo,
            .legacy,
            .livestream
        ]
    }

    nonisolated(unsafe) static var baseURL: BaseURL = {
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

    nonisolated(unsafe) static var appURLScheme: String = { AppURLScheme.universal.rawValue }()
}

extension AppEnvironment {

    enum AuthBaseURL: String {
        case universal = "https://pronto.getstream.io/api/auth/create-token"

        var url: URL { URL(string: rawValue)! }
    }

    nonisolated(unsafe) static var authBaseURL: URL = { AuthBaseURL.universal.url }()
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

    nonisolated(unsafe) static var loggedInView: LoggedInView = {
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

    nonisolated(unsafe) static var performanceTrackerVisibility: PerformanceTrackerVisibility = {
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

    nonisolated(unsafe) static var chatIntegration: ChatIntegration = {
        .enabled
    }()
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
                return BaseURL.pronto.url
            case .staging:
                return BaseURL.staging.url
            case .demo:
                return BaseURL.demo.url
            case .legacy:
                return BaseURL.legacy.url
            case .livestream:
                return BaseURL.livestream.url
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
            case .livestream:
                return "Livestream"
            }
        }
    }

    nonisolated(unsafe) static var supportedDeeplinks: [SupportedDeeplink] = {
        switch configuration {
        case .debug:
            return [.pronto, .demo, .staging, .legacy, .livestream]
        case .test:
            return [.pronto, .demo, .staging, .legacy]
        case .release:
            return [.demo, .livestream]
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

    nonisolated(unsafe) static var pictureInPictureIntegration: PictureInPictureIntegration = {
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

    nonisolated(unsafe) static var tokenExpiration: TokenExpiration = {
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

    nonisolated(unsafe) static var callExpiration: CallExpiration = .never
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

    nonisolated(unsafe) static var autoLeavePolicy: AutoLeavePolicy = .default
}

extension AppEnvironment {

    enum DisconnectionTimeout: Hashable, Debuggable {
        case never
        case twoMinutes
        case custom(TimeInterval)

        var title: String {
            switch self {
            case .never:
                return "Never"
            case .twoMinutes:
                return "2'"
            case let .custom(value):
                return "\(value)\""
            }
        }

        var duration: TimeInterval {
            switch self {
            case .never:
                return 0
            case .twoMinutes:
                return 2 * 60
            case let .custom(value):
                return value
            }
        }
    }

    nonisolated(unsafe) static var disconnectionTimeout: DisconnectionTimeout = .never
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
                return "h264"
            case .vp8:
                return "VP8"
            case .vp9:
                return "VP9"
            case .av1:
                return "AV1"
            }
        }

        var videoCodec: VideoCodec {
            switch self {
            case .h264:
                return .h264
            case .vp8:
                return .vp8
            case .vp9:
                return .vp9
            case .av1:
                return .av1
            }
        }
    }

    nonisolated(unsafe) static var preferredVideoCodec: PreferredVideoCodec = .h264
}

extension AppEnvironment {

    enum ClosedCaptionsIntegration: Hashable, Debuggable {
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

    nonisolated(unsafe) static var closedCaptionsIntegration: ClosedCaptionsIntegration = {
        .disabled
    }()
}

extension AppEnvironment {

    enum AudioSessionPolicyDebugConfiguration: Hashable, Debuggable, Sendable {
        case `default`, ownCapabilities, livestream

        var title: String {
            switch self {
            case .default:
                return "Default"
            case .ownCapabilities:
                return "OwnCapabilities"
            case .livestream:
                return "Livestream"
            }
        }

        var value: AudioSessionPolicy {
            switch self {
            case .default:
                return DefaultAudioSessionPolicy()
            case .ownCapabilities:
                return OwnCapabilitiesAudioSessionPolicy()
            case .livestream:
                return LivestreamAudioSessionPolicy()
            }
        }
    }

    nonisolated(unsafe) static var audioSessionPolicy: AudioSessionPolicyDebugConfiguration = {
        .default
    }()
}

extension AppEnvironment {

    nonisolated(unsafe) static var availableCallTypes: [String] = [
        .development,
        .default,
        .audioRoom,
        .livestream
    ]
    nonisolated(unsafe) static var preferredCallType: String?
}

extension AppEnvironment {

    enum ProximityPolicyDebugConfiguration: Hashable, Debuggable, Sendable, CaseIterable {
        case speaker, video

        var title: String {
            switch self {
            case .speaker:
                return "Speaker"
            case .video:
                return "Video"
            }
        }

        var value: ProximityPolicy {
            switch self {
            case .speaker:
                return SpeakerProximityPolicy()
            case .video:
                return VideoProximityPolicy()
            }
        }
    }

    nonisolated(unsafe) static var proximityPolicies: Set<ProximityPolicyDebugConfiguration> = {
        [.video, .speaker]
    }()
}

extension AppEnvironment {
    enum ModerationVideoPolicy: Hashable, Debuggable, Sendable {

        case blur(TimeInterval), pixelate(TimeInterval)

        var title: String {
            switch self {
            case let .blur(duration):
                if duration > 0 {
                    return "Blur (\(duration)s)"
                } else {
                    return "Blur"
                }
            case let .pixelate(duration):
                if duration > 0 {
                    return "Pixelate (\(duration)s)"
                } else {
                    return "Pixelate"
                }
            }
        }

        var value: Moderation.VideoPolicy {
            switch self {
            case .blur(let duration):
                return Moderation.VideoPolicy(duration: duration, videoFilter: .blur)
            case .pixelate(let duration):
                return Moderation.VideoPolicy(duration: duration, videoFilter: .pixelate)
            }
        }
    }

    nonisolated(unsafe) static var moderationVideoPolicy: ModerationVideoPolicy = .blur(20)
}

extension AppEnvironment {

    nonisolated(unsafe) static var clientCapabilities: Set<ClientCapability>?
}

extension ClientCapability: Debuggable {
    var title: String {
        switch self {
        case .subscriberVideoPause:
            "Subscriber video pause"
        }
    }
}

extension Logger.WebRTC.LogMode: Debuggable {
    var title: String {
        switch self {
        case .none:
            return "None"
        case .validFilesOnly:
            return "Valid Files only"
        case .all:
            return "All"
        }
    }
}

extension String: Debuggable {
    var title: String {
        self
    }
}

extension Bool: Debuggable {
    var title: String {
        self ? "True" : "False"
    }
}
