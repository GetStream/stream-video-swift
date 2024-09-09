//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockSignalServer: SFUSignalService, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = MockFunctionKey
        .allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockSignalServer, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: MockFunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    enum MockFunctionKey: Hashable, CaseIterable {
        case updateTrackMuteState
        case sendStats
        case startNoiseCancellation
        case stopNoiseCancellation
        case setPublisher
        case updateSubscriptions
        case sendAnswer
        case iCETrickle
    }

    enum MockFunctionInputKey {
        case updateMuteStates(request: Stream_Video_Sfu_Signal_UpdateMuteStatesRequest)
        case sendStats(request: Stream_Video_Sfu_Signal_SendStatsRequest)
        case startNoiseCancellation(request: Stream_Video_Sfu_Signal_StartNoiseCancellationRequest)
        case stopNoiseCancellation(request: Stream_Video_Sfu_Signal_StopNoiseCancellationRequest)
        case setPublisher(request: Stream_Video_Sfu_Signal_SetPublisherRequest)
        case updateSubscriptions(request: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest)
        case sendAnswer(request: Stream_Video_Sfu_Signal_SendAnswerRequest)
        case iCETrickle(request: Stream_Video_Sfu_Models_ICETrickle)

        func value<T>(as: T.Type) -> T? {
            switch self {
            case let .updateMuteStates(request):
                return request as? T
            case let .sendStats(request):
                return request as? T
            case let .startNoiseCancellation(request):
                return request as? T
            case let .stopNoiseCancellation(request):
                return request as? T
            case let .setPublisher(request):
                return request as? T
            case let .updateSubscriptions(request):
                return request as? T
            case let .sendAnswer(request):
                return request as? T
            case let .iCETrickle(request):
                return request as? T
            }
        }
    }
    
    convenience init() {
        self.init(
            httpClient: HTTPClient_Mock(),
            apiKey: .unique,
            hostname: .unique,
            token: .unique
        )

        stub(for: .updateTrackMuteState, with: Stream_Video_Sfu_Signal_UpdateMuteStatesResponse())
        stub(for: .sendStats, with: Stream_Video_Sfu_Signal_SendStatsResponse())
        stub(for: .startNoiseCancellation, with: Stream_Video_Sfu_Signal_StartNoiseCancellationResponse())
        stub(for: .stopNoiseCancellation, with: Stream_Video_Sfu_Signal_StopNoiseCancellationResponse())
        stub(for: .setPublisher, with: Stream_Video_Sfu_Signal_SetPublisherResponse())
        stub(for: .updateSubscriptions, with: Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse())
        stub(for: .sendAnswer, with: Stream_Video_Sfu_Signal_SendAnswerResponse())
        stub(for: .sendAnswer, with: Stream_Video_Sfu_Signal_SendAnswerResponse())
        stub(for: .iCETrickle, with: Stream_Video_Sfu_Signal_ICETrickleResponse())
    }

    override func updateMuteStates(
        updateMuteStatesRequest: Stream_Video_Sfu_Signal_UpdateMuteStatesRequest
    ) async throws -> Stream_Video_Sfu_Signal_UpdateMuteStatesResponse {
        stubbedFunctionInput[.updateTrackMuteState]?
            .append(.updateMuteStates(request: updateMuteStatesRequest))
        return stubbedFunction[.updateTrackMuteState] as! Stream_Video_Sfu_Signal_UpdateMuteStatesResponse
    }

    override func sendStats(
        sendStatsRequest: Stream_Video_Sfu_Signal_SendStatsRequest
    ) async throws -> Stream_Video_Sfu_Signal_SendStatsResponse {
        stubbedFunctionInput[.sendStats]?
            .append(.sendStats(request: sendStatsRequest))
        return stubbedFunction[.sendStats] as! Stream_Video_Sfu_Signal_SendStatsResponse
    }

    override func startNoiseCancellation(
        startNoiseCancellationRequest: Stream_Video_Sfu_Signal_StartNoiseCancellationRequest
    ) async throws -> Stream_Video_Sfu_Signal_StartNoiseCancellationResponse {
        stubbedFunctionInput[.startNoiseCancellation]?
            .append(.startNoiseCancellation(request: startNoiseCancellationRequest))
        return stubbedFunction[.startNoiseCancellation] as! Stream_Video_Sfu_Signal_StartNoiseCancellationResponse
    }

    override func stopNoiseCancellation(
        stopNoiseCancellationRequest: Stream_Video_Sfu_Signal_StopNoiseCancellationRequest
    ) async throws -> Stream_Video_Sfu_Signal_StopNoiseCancellationResponse {
        stubbedFunctionInput[.stopNoiseCancellation]?
            .append(.stopNoiseCancellation(request: stopNoiseCancellationRequest))
        return stubbedFunction[.stopNoiseCancellation] as! Stream_Video_Sfu_Signal_StopNoiseCancellationResponse
    }

    override func setPublisher(
        setPublisherRequest: Stream_Video_Sfu_Signal_SetPublisherRequest
    ) async throws -> Stream_Video_Sfu_Signal_SetPublisherResponse {
        stubbedFunctionInput[.setPublisher]?
            .append(.setPublisher(request: setPublisherRequest))
        return stubbedFunction[.setPublisher] as! Stream_Video_Sfu_Signal_SetPublisherResponse
    }

    override func updateSubscriptions(
        updateSubscriptionsRequest: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest
    ) async throws -> Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse {
        stubbedFunctionInput[.updateSubscriptions]?
            .append(.updateSubscriptions(request: updateSubscriptionsRequest))
        return stubbedFunction[.updateSubscriptions] as! Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse
    }

    override func sendAnswer(
        sendAnswerRequest: Stream_Video_Sfu_Signal_SendAnswerRequest
    ) async throws -> Stream_Video_Sfu_Signal_SendAnswerResponse {
        stubbedFunctionInput[.sendAnswer]?
            .append(.sendAnswer(request: sendAnswerRequest))
        return stubbedFunction[.sendAnswer] as! Stream_Video_Sfu_Signal_SendAnswerResponse
    }

    override func iceTrickle(
        iCETrickle: Stream_Video_Sfu_Models_ICETrickle
    ) async throws -> Stream_Video_Sfu_Signal_ICETrickleResponse {
        stubbedFunctionInput[.iCETrickle]?
            .append(.iCETrickle(request: iCETrickle))
        return stubbedFunction[.iCETrickle] as! Stream_Video_Sfu_Signal_ICETrickleResponse
    }
}
