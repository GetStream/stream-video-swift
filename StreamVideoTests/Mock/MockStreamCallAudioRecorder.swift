//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    func stub(for function: FunctionKey, with value: some Any) { stubbedFunction[function] = value }

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
                ignoreActiveCall
            case .stopRecording:
                ()
            }
        }
    }

    init() {
        super.init(filename: "mock_file")
        InjectedValues[\.callAudioRecorder] = self
    }

    override func startRecording(ignoreActiveCall: Bool = false) async {
        stubbedFunctionInput[.startRecording]?
            .append(.startRecording(ignoreActiveCall: ignoreActiveCall))
    }

    override func stopRecording() async {
        stubbedFunctionInput[.stopRecording]?.append(.stopRecording)
    }

    // Mock the metersPublisher
    override var metersPublisher: AnyPublisher<Float, Never> {
        Just(0.0).eraseToAnyPublisher()
    }
}
