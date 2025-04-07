//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class ProximityManager_Tests: XCTestCase, @unchecked Sendable {
    private nonisolated(unsafe) static var mockStreamVideo: MockStreamVideo! = .init()

    private var mockCurrentDevice: CurrentDevice! = .dummy { .phone }
    private lazy var mockCall: MockCall! = .init(.dummy())
    private lazy var subject: ProximityManager! = .init(mockCall)

    override class func setUp() {
        super.setUp()
        _ = mockStreamVideo
    }

    override func setUp() async throws {
        try await super.setUp()
        _ = mockCurrentDevice
        _ = mockCall
    }

    override func tearDown() async throws {
        subject = nil
        mockCall = nil
        mockCurrentDevice = nil
        try await super.tearDown()
    }

    override class func tearDown() {
        Self.mockStreamVideo = nil
        super.tearDown()
    }

    // MARK: - didUpdateActiveCall

    func test_didUpdateActiveCall_anotherCallIsNowActive_noPolicies_startObservationWasNotCalledOnProximityMonitor() async throws {
        let mockProximityMonitor = MockProximityMonitor()
        Self.mockStreamVideo.state.activeCall = MockCall(.dummy())

        await wait(for: 0.25)
        XCTAssertEqual(mockProximityMonitor.timesCalled(.startObservation), 0)
    }

    func test_didUpdateActiveCall_ownCallIsNowActive_noPolicies_startObservationWasNotCalledOnProximityMonitor() async throws {
        let mockProximityMonitor = MockProximityMonitor()
        Self.mockStreamVideo.state.activeCall = mockCall

        await wait(for: 0.25)
        XCTAssertEqual(mockProximityMonitor.timesCalled(.startObservation), 0)
    }

    func test_didUpdateActiveCall_anotherCallIsNowActive_withPolicies_startObservationWastCalledOnProximityMonitor() async throws {
        let mockProximityMonitor = MockProximityMonitor()
        await fulfillment { StreamVideoProviderKey.currentValue != nil }
        try subject.add(MockProximityPolicy())

        Self.mockStreamVideo.state.activeCall = MockCall(.dummy())

        XCTAssertEqual(mockProximityMonitor.timesCalled(.startObservation), 0)
    }

    func test_didUpdateActiveCall_ownCallIsNowActive_withPolicies_startObservationWastCalledOnProximityMonitor() async throws {
        let mockProximityMonitor = MockProximityMonitor()
        _ = subject
        try subject.add(MockProximityPolicy())

        Self.mockStreamVideo.state.activeCall = mockCall

        await fulfilmentInMainActor { mockProximityMonitor.timesCalled(.startObservation) == 1 }
    }

    func test_didUpdateActiveCall_ownCallIsNowInactiveAfterBeingActive_withoutPolicies_stopObservationWastNotCalledOnProximityMonitor(
    ) async throws {
        let mockProximityMonitor = MockProximityMonitor()
        _ = subject
        Self.mockStreamVideo.state.activeCall = mockCall
        await wait(for: 0.25)

        Self.mockStreamVideo.state.activeCall = nil

        await wait(for: 0.25)
        XCTAssertEqual(mockProximityMonitor.timesCalled(.stopObservation), 0)
    }

    func test_didUpdateActiveCall_ownCallIsNowInactiveAfterBeingActive_withPolicies_stopObservationWastCalledOnProximityMonitor(
    ) async throws {
        let mockProximityMonitor = MockProximityMonitor()
        _ = subject
        try subject.add(MockProximityPolicy())
        Self.mockStreamVideo.state.activeCall = mockCall
        await fulfilmentInMainActor { mockProximityMonitor.timesCalled(.startObservation) == 1 }

        Self.mockStreamVideo.state.activeCall = nil

        await fulfilmentInMainActor { mockProximityMonitor.timesCalled(.stopObservation) == 1 }
    }

    // MARK: - didUpdateProximity

    func test_didUpdateProximity_ownCallIsInactive_didUpdateProximityWasNotCalledOnPolicy() async throws {
        let mockProximityMonitor = MockProximityMonitor()
        let mockSubject = PassthroughSubject<ProximityState, Never>()
        mockProximityMonitor.stub(for: \.statePublisher, with: mockSubject.eraseToAnyPublisher())
        _ = subject
        let policy = MockProximityPolicy()
        try subject.add(policy)

        mockSubject.send(.near)

        await wait(for: 0.25)
        XCTAssertEqual(policy.timesCalled(.didUpdateProximity), 0)
    }

    func test_didUpdateProximity_ownCallIsActive_didUpdateProximityWasCalledOnPolicies() async throws {
        let mockProximityMonitor = MockProximityMonitor()
        let mockSubject = PassthroughSubject<ProximityState, Never>()
        mockProximityMonitor.stub(for: \.statePublisher, with: mockSubject.eraseToAnyPublisher())
        _ = subject
        let policyA = MockProximityPolicy()
        try subject.add(policyA)
        Self.mockStreamVideo.state.activeCall = mockCall
        await fulfilmentInMainActor { mockProximityMonitor.timesCalled(.startObservation) == 1 }

        mockSubject.send(.near)

        await wait(for: 0.25)
        XCTAssertEqual(policyA.recordedInputPayload((ProximityState, Call).self, for: .didUpdateProximity)?.first?.0, .near)
        XCTAssertEqual(
            policyA.recordedInputPayload((ProximityState, Call).self, for: .didUpdateProximity)?.first?.1.cId,
            mockCall.cId
        )
    }
}
