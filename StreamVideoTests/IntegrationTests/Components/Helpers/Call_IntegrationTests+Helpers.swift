//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

extension Call_IntegrationTests {
    struct Helpers: Sendable {
        @Injected(\.audioStore) private var audioStore

        enum LoggingMode { case none, sdk, webrtc, all }

        var duringDismantleObservedAllCallEnded = true

        var authentication: AuthenticationHelper
        var configuration: ConfigurationHelper
        var client: StreamVideoHelper
        var users: UserHelper
        var permissions: PermissionsHelper

        private var registeredCalls: [String: Call] = [:]

        init(
            loggingMode: LoggingMode = .none,
            configuration: ConfigurationHelper = .init(),
            authentication: AuthenticationHelper = .init(),
            client: StreamVideoHelper = .init(),
            user: UserHelper = .init(),
            permissions: PermissionsHelper = .init()
        ) {
            self.configuration = configuration
            self.authentication = authentication
            self.client = client
            self.users = user
            self.permissions = permissions

            switch loggingMode {
            case .none:
                LogConfig.webRTCLogsEnabled = false
                LogConfig.level = .error
            case .sdk:
                LogConfig.webRTCLogsEnabled = false
                LogConfig.level = .debug
            case .webrtc:
                LogConfig.webRTCLogsEnabled = true
                LogConfig.level = .error
            case .all:
                LogConfig.webRTCLogsEnabled = true
                LogConfig.level = .debug
            }
        }

        mutating func dismantle() async throws {
            if duringDismantleObservedAllCallEnded {
                for call in registeredCalls.values {
                    call.leave()
                    _ = try await NotificationCenter
                        .default
                        .publisher(for: .init(CallNotification.callEnded))
                        .compactMap { ($0.object as? Call)?.cId }
                        .filter { $0 == call.cId }
                        .nextValue(timeout: 2)
                }
            }
            registeredCalls = [:]

            audioStore
                .dispatch(.setAudioDeviceModule(nil))

            _ = try await audioStore
                .publisher(\.audioDeviceModule)
                .filter { $0 == nil }
                .nextValue(timeout: 2)

            await client.dismantle()
        }

        // MARK: - CallFlow

        mutating func callFlow(
            id: String,
            type: String,
            userId: String,
            environment: String = "pronto",
            clientResolutionMode: StreamVideoHelper.ClientResolutionMode = .ignoreCache
        ) async throws -> CallFlow<Void> {
            let authentication = try await authentication
                .authenticate(userId: userId, environment: environment)
            let client = try await client.buildClient(
                apiKey: authentication.apiKey,
                token: authentication.token,
                userId: userId,
                connectMode: .afterInit,
                clientResolutionMode: clientResolutionMode,
                clientRegisterMode: .auto
            )
            let call = client.call(callType: type, callId: id)
            registeredCalls[userId] = call
            return .init(
                client: client,
                call: call
            )
        }

        // MARK: - Raw

        func call(
            id: String,
            type: String,
            userId: String,
            clientResolutionMode: StreamVideoHelper.ClientResolutionMode = .ignoreCache
        ) async throws -> Call {
            let authentication = try await authentication
                .authenticate(userId: userId)
            let client = try await client.buildClient(
                apiKey: authentication.apiKey,
                token: authentication.token,
                userId: userId,
                connectMode: .afterInit,
                clientResolutionMode: clientResolutionMode,
                clientRegisterMode: .auto
            )
            return client.call(callType: type, callId: id)
        }
    }
}
