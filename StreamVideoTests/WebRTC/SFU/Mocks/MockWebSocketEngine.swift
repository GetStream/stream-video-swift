//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebSocketEngine: WebSocketEngine, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case connect
        case disconnect
        case disconnectWithCode
        case sendPing
        case sendMessage
        case sendJSON
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    func stub<T>(for keyPath: KeyPath<MockWebSocketEngine, T>, with value: T) {}
    func stub<T>(for function: MockFunctionKey, with value: T) {}

    enum FunctionInput: Payloadable {
        case connect
        case disconnect
        case disconnectWithCode(URLSessionWebSocketTask.CloseCode)
        case sendPing
        case sendMessage(message: SendableEvent)
        case sendJSON(json: Codable)

        var payload: Any {
            switch self {
            case .connect:
                return ()
            case .disconnect:
                return ()
            case .sendPing:
                return ()
            case let .sendMessage(message):
                return message
            case let .sendJSON(json):
                return json
            case let .disconnectWithCode(closeCode):
                return closeCode
            }
        }
    }

    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInput]] = MockFunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInput]]()) { $0[$1] = [] }

    let request: URLRequest
    let callbackQueue: DispatchQueue
    weak var delegate: WebSocketEngineDelegate?

    convenience init() {
        self.init(
            request: .init(url: .init(string: "https://getstream.io")!),
            sessionConfiguration: .default,
            callbackQueue: .main
        )
    }

    init(
        request: URLRequest,
        sessionConfiguration: URLSessionConfiguration,
        callbackQueue: DispatchQueue
    ) {
        self.request = request
        self.callbackQueue = callbackQueue
    }

    func connect() {
        stubbedFunctionInput[.connect]?.append(.connect)
    }

    func disconnect() {
        stubbedFunctionInput[.disconnect]?.append(.disconnect)
    }

    func disconnect(with code: URLSessionWebSocketTask.CloseCode) {
        stubbedFunctionInput[.disconnectWithCode]?.append(.disconnectWithCode(code))
    }

    func send(message: any SendableEvent) {
        stubbedFunctionInput[.sendMessage]?.append(.sendMessage(message: message))
    }

    func send(jsonMessage: any Codable) {
        stubbedFunctionInput[.sendJSON]?.append(.sendJSON(json: jsonMessage))
    }

    func sendPing() {
        stubbedFunctionInput[.sendPing]?.append(.sendPing)
    }
}
