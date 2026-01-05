//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockDefaultAPI: DefaultAPI, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case acceptCall
        case rejectCall
        case getOrCreateCall
    }

    enum MockFunctionInputKey: Payloadable {
        case acceptCall(type: String, id: String)
        case rejectCall(type: String, id: String, request: RejectCallRequest)
        case getOrCreateCall(type: String, id: String, getOrCreateCallRequest: GetOrCreateCallRequest)

        var payload: Any {
            switch self {
            case let .acceptCall(type, id):
                return (type, id)

            case let .rejectCall(type, id, request):
                return (type, id, request)

            case let .getOrCreateCall(type, id, request):
                return (type, id, request)
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockDefaultAPI, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    convenience init() {
        self.init(
            basePath: .unique,
            transport: HTTPClient_Mock(),
            middlewares: []
        )
    }

    // MARK: - Mocks

    override func getOrCreateCall(
        type: String,
        id: String,
        getOrCreateCallRequest: GetOrCreateCallRequest
    ) async throws -> GetOrCreateCallResponse {
        stubbedFunctionInput[.getOrCreateCall]?.append(
            .getOrCreateCall(
                type: type,
                id: id,
                getOrCreateCallRequest: getOrCreateCallRequest
            )
        )
        if let response = stubbedFunction[.getOrCreateCall] as? GetOrCreateCallResponse {
            return response
        } else if let error = stubbedFunction[.getOrCreateCall] as? Error {
            throw error
        } else {
            return try await super.getOrCreateCall(
                type: type,
                id: id,
                getOrCreateCallRequest: getOrCreateCallRequest
            )
        }
    }

    override func acceptCall(
        type: String,
        id: String
    ) async throws -> AcceptCallResponse {
        stubbedFunctionInput[.acceptCall]?.append(.acceptCall(type: type, id: id))
        if let response = stubbedFunction[.acceptCall] as? AcceptCallResponse {
            return response
        } else if let error = stubbedFunction[.acceptCall] as? Error {
            throw error
        } else {
            return try await super.acceptCall(type: type, id: id)
        }
    }

    override func rejectCall(
        type: String,
        id: String,
        rejectCallRequest: RejectCallRequest
    ) async throws -> RejectCallResponse {
        stubbedFunctionInput[.rejectCall]?.append(
            .rejectCall(
                type: type,
                id: id,
                request: rejectCallRequest
            )
        )
        if let response = stubbedFunction[.rejectCall] as? RejectCallResponse {
            return response
        } else if let error = stubbedFunction[.rejectCall] as? Error {
            throw error
        } else {
            return try await super.rejectCall(
                type: type,
                id: id,
                rejectCallRequest: rejectCallRequest
            )
        }
    }
}
