//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo

final class MockSFUWebSocket: SFUWebSocket, @unchecked Sendable {
    enum FunctionKey: Hashable {
        case connect
        case disconnect
        case disconnectAsync
        case disconnectForReconfiguration
        case send
        case inject
    }

    private let lock = NSLock()
    private let stateSubject = CurrentValueSubject<
        WebSocketConnectionState,
        Never
    >(.initialized)
    private let receivedEventSubject = PassthroughSubject<
        Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload,
        Never
    >()
    private var calls: [FunctionKey: Int] = [:]
    private var sentMessages: [any SendableEvent] = []

    override var connectionState: WebSocketConnectionState {
        stateSubject.value
    }

    override var connectionStatePublisher: AnyPublisher<
        WebSocketConnectionState,
        Never
    > {
        stateSubject.eraseToAnyPublisher()
    }

    override var eventPublisher: AnyPublisher<
        Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload,
        Never
    > {
        receivedEventSubject.eraseToAnyPublisher()
    }

    init(
        connectURL: URL = URL(string: "https://getstream.io")!
    ) {
        super.init(
            url: connectURL,
            sessionConfiguration: .ephemeral
        )
    }

    func timesCalled(_ key: FunctionKey) -> Int {
        withLock { calls[key, default: 0] }
    }

    func recordedInputPayload<T>(
        _ type: T.Type,
        for key: FunctionKey
    ) -> [T]? {
        guard key == .send else { return nil }
        return withLock { sentMessages.compactMap { $0 as? T } }
    }

    func simulate(state: WebSocketConnectionState) {
        stateSubject.send(state)
    }

    func receive(
        _ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload
    ) {
        inject(payload)
    }

    override func connect() {
        record(.connect)
        stateSubject.send(.connecting)
    }

    override func disconnect() async {
        record(.disconnectAsync)
        stateSubject.send(.disconnecting(source: .userInitiated))
    }

    override func disconnect(code: URLSessionWebSocketTask.CloseCode) {
        record(.disconnect)
        stateSubject.send(.disconnecting(source: .userInitiated))
    }

    override func disconnectForReconfiguration() {
        record(.disconnectForReconfiguration)
        stateSubject.send(.disconnecting(source: .userInitiated))
    }

    override func send(_ message: any SendableEvent) {
        withLock {
            calls[.send, default: 0] += 1
            sentMessages.append(message)
        }
    }

    override func inject(
        _ payload: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload
    ) {
        receivedEventSubject.send(payload)
    }

    private func record(_ key: FunctionKey) {
        withLock { calls[key, default: 0] += 1 }
    }

    private func withLock<T>(_ action: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return action()
    }
}
