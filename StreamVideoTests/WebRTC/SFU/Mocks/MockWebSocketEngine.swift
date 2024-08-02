//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebSocketEngine: WebSocketEngine {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable {
        case connect
        case disconnect
        case sendPing
    }

    private(set) var timesFunctionWasCalled: [FunctionKey: Int] = [:]
    private(set) var sendWasCalledWithMessage: SendableEvent?
    private(set) var sendWasCalledWithJSON: Codable?

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

    func send(message: any SendableEvent) {
        sendWasCalledWithMessage = message
    }

    func send(jsonMessage: any Codable) {
        sendWasCalledWithJSON = jsonMessage
    }

    func sendPing() {
        if let value = timesFunctionWasCalled[.sendPing] {
            timesFunctionWasCalled[.sendPing] = value + 1
        } else {
            timesFunctionWasCalled[.sendPing] = 1
        }
    }
}
