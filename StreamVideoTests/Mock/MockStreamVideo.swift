//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockStreamVideo: StreamVideo, Mockable {

    typealias FunctionKey = MockStreamVideoFunctionKey

    enum MockStreamVideoFunctionKey: Hashable {
        case call
        case connect
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]

    override var state: StreamVideo.State {
        get { self[dynamicMember: \.state] }
        set { _ = newValue }
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
            environment: environment
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
        callSettings: CallSettings? = nil
    ) -> Call {
        stubbedFunction[.call] as! Call
    }

    override func connect() async throws {
        if let error = stubbedFunction[.connect] as? Error {
            throw error
        }
    }
}
