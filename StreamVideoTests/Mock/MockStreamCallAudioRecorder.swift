//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockStreamCallAudioRecorder: StreamCallAudioRecorder, @unchecked Sendable, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockStreamCallAudioRecorder, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case startRecording
        case stopRecording
    }

    enum MockFunctionInputKey: Payloadable {
        case startRecording(ignoreActiveCall: Bool)
        case stopRecording

        var payload: Any {
            switch self {
            case let .startRecording(ignoreActiveCall):
                return ignoreActiveCall
            case .stopRecording:
                return ()
            }
        }
    }

    let mockStore: Store<Namespace> = Namespace.store(
        initialState: .initial,
        middleware: []
    )

    init() {
        super.init(mockStore)
        InjectedValues[\.callAudioRecorder] = self
    }

    override func startRecording(ignoreActiveCall: Bool = false) {
        stubbedFunctionInput[.startRecording]?
            .append(.startRecording(ignoreActiveCall: ignoreActiveCall))
    }

    override func stopRecording() {
        stubbedFunctionInput[.stopRecording]?.append(.stopRecording)
    }
}
