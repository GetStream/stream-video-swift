//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockCall: Call, Mockable {

    typealias FunctionKey = MockCallFunctionKey

    enum MockCallFunctionKey: Hashable {
        case get
        case accept
        case join
    }

    var stubbedProperty: [String: Any]
    var stubbedFunction: [FunctionKey: Any] = [:]

    override var state: CallState {
        get { self[dynamicMember: \.state] }
        set { _ = newValue }
    }

    @MainActor
    init(
        _ source: Call = .dummy()
    ) {
        stubbedProperty = [
            MockCall.propertyKey(for: \.state): CallState()
        ]

        super.init(
            callType: source.callType,
            callId: source.callId,
            coordinatorClient: source.coordinatorClient,
            callController: source.callController
        )
    }

    func stub<T>(for keyPath: KeyPath<MockCall, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    override func get(
        membersLimit: Int? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> GetCallResponse {
        stubbedFunction[.get] as! GetCallResponse
    }

    override func accept() async throws -> AcceptCallResponse {
        stubbedFunction[.accept] as! AcceptCallResponse
    }

    override func join(
        create: Bool = false,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false,
        callSettings: CallSettings? = nil
    ) async throws -> JoinCallResponse {
        if let stub = stubbedFunction[.join] as? JoinCallResponse {
            return stub
        } else {
            return try await super.join(
                create: create,
                options: options,
                ring: ring,
                notify: notify,
                callSettings: callSettings
            )
        }
    }
}
