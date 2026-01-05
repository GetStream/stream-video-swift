//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

final class MockCall: Call, Mockable, @unchecked Sendable {

    typealias FunctionKey = MockCallFunctionKey
    typealias FunctionInputKey = MockCallFunctionInputKey

    enum MockCallFunctionKey: Hashable, CaseIterable {
        case create
        case get
        case accept
        case reject
        case join
        case updateTrackSize
        case callKitActivated
        case ring
        case setVideoFilter
    }

    enum MockCallFunctionInputKey: Payloadable {
        case join(
            create: Bool,
            options: CreateCallOptions?,
            ring: Bool,
            notify: Bool,
            callSettings: CallSettings?
        )

        case updateTrackSize(trackSize: CGSize, participant: CallParticipant)

        case callKitActivated(audioSession: AVAudioSessionProtocol)

        case reject(reason: String?)

        case ring(request: RingCallRequest)

        case setVideoFilter(videoFilter: VideoFilter?)

        var payload: Any {
            switch self {
            case let .join(create, options, ring, notify, callSettings):
                return (create, options, ring, notify, callSettings)

            case let .updateTrackSize(trackSize, participant):
                return (trackSize, participant)

            case let .callKitActivated(audioSession):
                return audioSession

            case let .reject(reason):
                return reason ?? ""

            case let .ring(request):
                return request

            case let .setVideoFilter(videoFilter):
                return videoFilter
            }
        }
    }

    var stubbedProperty: [String: Any]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }

    override var state: CallState {
        get { self[dynamicMember: \.state] }
        set { stub(for: \.state, with: newValue) }
    }

    override var eventPublisher: AnyPublisher<VideoEvent, Never> {
        if containsStub(for: \.eventPublisher) {
            return self[dynamicMember: \.eventPublisher]
        } else {
            return super.eventPublisher
        }
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

    override func create(
        members: [MemberRequest]? = nil,
        memberIds: [String]? = nil,
        custom: [String: RawJSON]? = nil,
        startsAt: Date? = nil,
        team: String? = nil,
        ring: Bool = false,
        notify: Bool = false,
        maxDuration: Int? = nil,
        maxParticipants: Int? = nil,
        backstage: BackstageSettingsRequest? = nil,
        video: Bool? = nil,
        transcription: TranscriptionSettingsRequest? = nil
    ) async throws -> CallResponse {
        if let response = stubbedFunction[.create] as? CallResponse {
            return response
        } else if let error = stubbedFunction[.create] as? Error {
            throw error
        } else {
            return try await super.create(
                members: members,
                memberIds: memberIds,
                custom: custom,
                startsAt: startsAt,
                team: team,
                ring: ring,
                notify: notify,
                maxDuration: maxDuration,
                maxParticipants: maxParticipants,
                backstage: backstage,
                video: video,
                transcription: transcription
            )
        }
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

    override func reject(reason: String? = nil) async throws -> RejectCallResponse {
        stubbedFunctionInput[.reject]?.append(.reject(reason: reason))
        return stubbedFunction[.reject] as! RejectCallResponse
    }

    override func join(
        create: Bool = false,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false,
        callSettings: CallSettings? = nil
    ) async throws -> JoinCallResponse {
        stubbedFunctionInput[.join]?.append(
            .join(
                create: create,
                options: options,
                ring: ring,
                notify: notify,
                callSettings: callSettings
            )
        )
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

    override func updateTrackSize(
        _ trackSize: CGSize,
        for participant: CallParticipant
    ) async {
        stubbedFunctionInput[.updateTrackSize]?.append(
            .updateTrackSize(trackSize: trackSize, participant: participant)
        )
    }

    override func ring(request: RingCallRequest) async throws -> RingCallResponse {
        stubbedFunctionInput[.ring]?.append(.ring(request: request))
        if let response = stubbedFunction[.ring] as? RingCallResponse {
            return response
        } else if let error = stubbedFunction[.ring] as? Error {
            throw error
        } else {
            // Default to a benign response if not stubbed to simplify tests
            return RingCallResponse(duration: "0", membersIds: request.membersIds ?? [])
        }
    }

    override func setVideoFilter(_ videoFilter: VideoFilter?) {
        stubbedFunctionInput[.setVideoFilter]?.append(
            .setVideoFilter(
                videoFilter: videoFilter
            )
        )
    }
}
