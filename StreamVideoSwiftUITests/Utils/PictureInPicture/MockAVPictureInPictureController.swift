//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI

final class MockAVPictureInPictureController: StreamPictureInPictureControllerProtocol, Mockable {
    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockAVPictureInPictureController, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub(for function: FunctionKey, with value: some Any) {}

    enum MockFunctionKey: Hashable, CaseIterable {
        case stopPictureInPicture
    }

    enum MockFunctionInputKey: Payloadable {
        case stopPictureInPicture

        var payload: Any {
            switch self {
            case .stopPictureInPicture:
                ()
            }
        }
    }

    var isPictureInPictureActivePublisher: AnyPublisher<Bool, Never> {
        get { self[dynamicMember: \.isPictureInPictureActivePublisher] }
        set { stub(for: \.isPictureInPictureActivePublisher, with: newValue) }
    }

    func stopPictureInPicture() {
        stubbedFunctionInput[.stopPictureInPicture]?.append(.stopPictureInPicture)
    }
}
