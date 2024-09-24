//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockSignalServer: SFUSignalService, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    var stubbedFunctionInput: [MockFunctionKey: [FunctionInputKey]] = [:]
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

    private(set) var updateMuteStatesWasCalledWithRequest: Stream_Video_Sfu_Signal_UpdateMuteStatesRequest?
    var sendStatsWasCalledWithRequest: Stream_Video_Sfu_Signal_SendStatsRequest?
    private(set) var startNoiseCancellationWasCalledWithRequest: Stream_Video_Sfu_Signal_StartNoiseCancellationRequest?
    private(set) var stopNoiseCancellationWasCalledWithRequest: Stream_Video_Sfu_Signal_StopNoiseCancellationRequest?
    private(set) var setPublisherWasCalledWithRequest: Stream_Video_Sfu_Signal_SetPublisherRequest?
    private(set) var updateSubscriptionsWasCalledWithRequest: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest?
    private(set) var sendAnswerWasCalledWithRequest: Stream_Video_Sfu_Signal_SendAnswerRequest?
    private(set) var iCETrickleWasCalledWithRequest: Stream_Video_Sfu_Models_ICETrickle?

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
        updateMuteStatesWasCalledWithRequest = updateMuteStatesRequest
        return stubbedFunction[.updateTrackMuteState] as! Stream_Video_Sfu_Signal_UpdateMuteStatesResponse
    }

    override func sendStats(
        sendStatsRequest: Stream_Video_Sfu_Signal_SendStatsRequest
    ) async throws -> Stream_Video_Sfu_Signal_SendStatsResponse {
        sendStatsWasCalledWithRequest = sendStatsRequest
        return stubbedFunction[.sendStats] as! Stream_Video_Sfu_Signal_SendStatsResponse
    }

    override func startNoiseCancellation(
        startNoiseCancellationRequest: Stream_Video_Sfu_Signal_StartNoiseCancellationRequest
    ) async throws -> Stream_Video_Sfu_Signal_StartNoiseCancellationResponse {
        startNoiseCancellationWasCalledWithRequest = startNoiseCancellationRequest
        return stubbedFunction[.startNoiseCancellation] as! Stream_Video_Sfu_Signal_StartNoiseCancellationResponse
    }

    override func stopNoiseCancellation(
        stopNoiseCancellationRequest: Stream_Video_Sfu_Signal_StopNoiseCancellationRequest
    ) async throws -> Stream_Video_Sfu_Signal_StopNoiseCancellationResponse {
        stopNoiseCancellationWasCalledWithRequest = stopNoiseCancellationRequest
        return stubbedFunction[.stopNoiseCancellation] as! Stream_Video_Sfu_Signal_StopNoiseCancellationResponse
    }

    override func setPublisher(
        setPublisherRequest: Stream_Video_Sfu_Signal_SetPublisherRequest
    ) async throws -> Stream_Video_Sfu_Signal_SetPublisherResponse {
        setPublisherWasCalledWithRequest = setPublisherRequest
        return stubbedFunction[.setPublisher] as! Stream_Video_Sfu_Signal_SetPublisherResponse
    }

    override func updateSubscriptions(
        updateSubscriptionsRequest: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest
    ) async throws -> Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse {
        updateSubscriptionsWasCalledWithRequest = updateSubscriptionsRequest
        return stubbedFunction[.updateSubscriptions] as! Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse
    }

    override func sendAnswer(
        sendAnswerRequest: Stream_Video_Sfu_Signal_SendAnswerRequest
    ) async throws -> Stream_Video_Sfu_Signal_SendAnswerResponse {
        sendAnswerWasCalledWithRequest = sendAnswerRequest
        return stubbedFunction[.sendAnswer] as! Stream_Video_Sfu_Signal_SendAnswerResponse
    }

    override func iceTrickle(
        iCETrickle: Stream_Video_Sfu_Models_ICETrickle
    ) async throws -> Stream_Video_Sfu_Signal_ICETrickleResponse {
        iCETrickleWasCalledWithRequest = iCETrickle
        return stubbedFunction[.iCETrickle] as! Stream_Video_Sfu_Signal_ICETrickleResponse
    }
}
