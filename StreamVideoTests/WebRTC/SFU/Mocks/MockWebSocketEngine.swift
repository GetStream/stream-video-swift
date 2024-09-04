//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebSocketEngine: WebSocketEngine {

    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case connect
        case disconnect
        case disconnectWithCode
        case sendPing
        case send
    }

    enum FunctionInput {
        case send(message: SendableEvent?, json: Codable?)
        case disconnectWithCode(URLSessionWebSocketTask.CloseCode)
    }

    private(set) var timesFunctionWasCalled: [FunctionKey: Int] = [:]
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
        if let value = timesFunctionWasCalled[.connect] {
            timesFunctionWasCalled[.connect] = value + 1
        } else {
            timesFunctionWasCalled[.connect] = 1
        }
    }

    func disconnect() {
        if let value = timesFunctionWasCalled[.disconnect] {
            timesFunctionWasCalled[.disconnect] = value + 1
        } else {
            timesFunctionWasCalled[.disconnect] = 1
        }
    }

    func disconnect(with code: URLSessionWebSocketTask.CloseCode) {
        stubbedFunctionInput[.disconnectWithCode]?.append(.disconnectWithCode(code))
        if let value = timesFunctionWasCalled[.disconnectWithCode] {
            timesFunctionWasCalled[.disconnectWithCode] = value + 1
        } else {
            timesFunctionWasCalled[.disconnectWithCode] = 1
        }
    }

    func send(message: any SendableEvent) {
        stubbedFunctionInput[.send]?.append(.send(message: message, json: nil))
    }

    func send(jsonMessage: any Codable) {
        stubbedFunctionInput[.send]?.append(.send(message: nil, json: jsonMessage))
    }

    func sendPing() {
        if let value = timesFunctionWasCalled[.sendPing] {
            timesFunctionWasCalled[.sendPing] = value + 1
        } else {
            timesFunctionWasCalled[.sendPing] = 1
        }
    }
}
