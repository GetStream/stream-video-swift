//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo

final class MockSFUWebSocket: SFUWebSocketProtocol, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case connect
        case disconnect
        case disconnectAsync
        case disconnectForReconfiguration
        case send
        case inject
    }

    enum FunctionInput: Payloadable {
        case connect
        case disconnect(code: URLSessionWebSocketTask.CloseCode)
        case disconnectAsync
        case disconnectForReconfiguration
        case send(message: any StreamCore.SendableEvent)
        case inject(payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload)

        var payload: Any {
            switch self {
            case .connect:
                return ()
            case let .disconnect(code):
                return code
            case .disconnectAsync:
                return ()
            case .disconnectForReconfiguration:
                return ()
            case let .send(message):
                return message
            case let .inject(payload):
                return payload
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    var stubbedFunctionInput: [FunctionKey: [FunctionInput]] = MockFunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInput]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockSFUWebSocket, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - SFUWebSocketProtocol

    var connectURL: URL = .init(string: "https://getstream.io")!

    @Published var connectionStateValue: WebSocketConnectionState = .initialized
    var connectionState: WebSocketConnectionState { connectionStateValue }
    var connectionStatePublisher: AnyPublisher<WebSocketConnectionState, Never> {
        $connectionStateValue.eraseToAnyPublisher()
    }

    let eventSubject = PassthroughSubject<
        Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload,
        Never
    >()
    var eventPublisher: AnyPublisher<Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func connect() {
        stubbedFunctionInput[.connect]?.append(.connect)
    }

    func disconnect() async {
        stubbedFunctionInput[.disconnectAsync]?.append(.disconnectAsync)
    }

    func disconnect(code: URLSessionWebSocketTask.CloseCode) {
        stubbedFunctionInput[.disconnect]?.append(.disconnect(code: code))
    }

    func disconnectForReconfiguration() {
        stubbedFunctionInput[.disconnectForReconfiguration]?.append(
            .disconnectForReconfiguration
        )
    }

    func send(_ message: any StreamCore.SendableEvent) {
        stubbedFunctionInput[.send]?.append(.send(message: message))
    }

    func inject(_ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) {
        stubbedFunctionInput[.inject]?.append(.inject(payload: payload))
        eventSubject.send(payload)
    }

    // MARK: - Helpers

    /// Simulates a connection-state change.
    func simulate(state: WebSocketConnectionState) {
        connectionStateValue = state
    }

    /// Pushes an SFU event payload through the event stream.
    func receive(_ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) {
        eventSubject.send(payload)
    }
}
