//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockStreamVideo: StreamVideo, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockStreamVideoFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockStreamVideoFunctionKey: Hashable, CaseIterable {
        case call
        case connect
    }

    enum MockFunctionInputKey: Payloadable {
        case call(
            callType: String,
            callId: String,
            callSettings: CallSettings?
        )

        var payload: Any {
            switch self {
            case let .call(callType, callId, callSettings):
                return (callType, callId, callSettings)
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }

    override var state: StreamVideo.State {
        get { self[dynamicMember: \.state] }
        set { stub(for: \.state, with: newValue) }
    }

    init(
        stubbedProperty: [String: Any] = [:],
        stubbedFunction: [FunctionKey: Any] = [:],
        apiKey: String = .unique,
        user: User = .dummy(),
        token: UserToken = .empty,
        videoConfig: VideoConfig = .init(),
        tokenProvider: @escaping UserTokenProvider = { _ in },
        pushNotificationsConfig: PushNotificationsConfig = .default,
        environment: Environment = .init()
    ) {
        var stubbedProperty = stubbedProperty
        if stubbedProperty[MockStreamVideo.propertyKey(for: \.state)] == nil {
            stubbedProperty[MockStreamVideo.propertyKey(for: \.state)] = MockStreamVideo.State(user: user)
        }

        self.stubbedProperty = stubbedProperty
        self.stubbedFunction = stubbedFunction

        super.init(
            apiKey: apiKey,
            user: user,
            token: token,
            videoConfig: videoConfig,
            tokenProvider: tokenProvider,
            pushNotificationsConfig: pushNotificationsConfig,
            environment: environment,
            autoConnectOnInit: false
        )
    }

    func stub<T>(for keyPath: KeyPath<MockStreamVideo, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: MockStreamVideoFunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    override func call(
        callType: String,
        callId: String,
        callSettings: CallSettings? = nil,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> Call {
        stubbedFunctionInput[.call]?.append(
            .call(
                callType: callType,
                callId: callId,
                callSettings: callSettings
            )
        )
        return stubbedFunction[.call] as! Call
    }

    override func connect() async throws {
        if let error = stubbedFunction[.connect] as? Error {
            throw error
        }
    }

    func process(
        _ event: WrappedEvent,
        postNotification: Bool = true,
        completion: (@Sendable () -> Void)? = nil
    ) {
        eventNotificationCenter.process(
            event,
            postNotification: postNotification,
            completion: completion
        )
    }
}
