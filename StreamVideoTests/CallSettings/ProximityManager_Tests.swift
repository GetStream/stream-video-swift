//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class ProximityManager_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockProximityMonitor: MockProximityMonitor! = .init()
    private lazy var mockCall: MockCall! = .init(.dummy())
    private lazy var mockActiveCallSubject: PassthroughSubject<Call?, Never>! = .init()
    private lazy var subject: ProximityManager! = .init(
        mockCall,
        activeCallPublisher: mockActiveCallSubject.eraseToAnyPublisher()
    )

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        CurrentDevice.currentValue.didUpdate(.phone)
        _ = mockProximityMonitor
        _ = mockCall
        _ = subject
    }

    override func tearDown() async throws {
        subject = nil
        mockCall = nil
        mockActiveCallSubject = nil
        mockProximityMonitor = nil
        CurrentDevice.currentValue = .init()
        try await super.tearDown()
    }

    // MARK: - didUpdateActiveCall

    func test_didUpdateActiveCall_anotherCallIsNowActive_noPolicies_startObservationWasNotCalledOnProximityMonitor() async throws {
        mockActiveCallSubject.send(mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockProximityMonitor.timesCalled(.startObservation), 0)
    }

    func test_didUpdateActiveCall_ownCallIsNowActive_noPolicies_startObservationWasNotCalledOnProximityMonitor() async throws {
        mockActiveCallSubject.send(mockCall)

        await wait(for: 0.25)
        XCTAssertEqual(mockProximityMonitor.timesCalled(.startObservation), 0)
    }

    func test_didUpdateActiveCall_anotherCallIsNowActive_withPolicies_startObservationWastCalledOnProximityMonitor() async throws {
        try subject.add(MockProximityPolicy())

        mockActiveCallSubject.send(MockCall(.dummy()))
        await wait(for: 0.5)

        XCTAssertEqual(mockProximityMonitor.timesCalled(.startObservation), 0)
    }

    @MainActor
    func test_didUpdateActiveCall_ownCallIsNowActive_withPolicies_startObservationWastCalledOnProximityMonitor() async throws {
        try subject.add(MockProximityPolicy())
        mockActiveCallSubject.send(mockCall)

        await fulfilmentInMainActor { self.mockProximityMonitor.timesCalled(.startObservation) == 1 }
    }

    func test_didUpdateActiveCall_ownCallIsNowInactiveAfterBeingActive_withoutPolicies_stopObservationWastNotCalledOnProximityMonitor(
    ) async throws {
        _ = subject
        mockActiveCallSubject.send(mockCall)
        await wait(for: 0.25)

        mockActiveCallSubject.send(nil)

        await wait(for: 0.25)
        XCTAssertEqual(mockProximityMonitor.timesCalled(.stopObservation), 0)
    }

    func test_didUpdateActiveCall_ownCallIsNowInactiveAfterBeingActive_withPolicies_stopObservationWastCalledOnProximityMonitor(
    ) async throws {
        try subject.add(MockProximityPolicy())
        mockActiveCallSubject.send(mockCall)
        await fulfilmentInMainActor { self.mockProximityMonitor.timesCalled(.startObservation) == 1 }

        mockActiveCallSubject.send(nil)

        await fulfilmentInMainActor { self.mockProximityMonitor.timesCalled(.stopObservation) == 1 }
    }

    // MARK: - didUpdateProximity

    func test_didUpdateProximity_ownCallIsInactive_didUpdateProximityWasNotCalledOnPolicy() async throws {
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
        let mockSubject = PassthroughSubject<ProximityState, Never>()
        mockProximityMonitor.stub(for: \.statePublisher, with: mockSubject.eraseToAnyPublisher())
        _ = subject
        let policyA = MockProximityPolicy()
        try subject.add(policyA)
        mockActiveCallSubject.send(mockCall)
        await fulfilmentInMainActor { self.mockProximityMonitor.timesCalled(.startObservation) == 1 }

        mockSubject.send(.near)

        await wait(for: 0.25)
        XCTAssertEqual(policyA.recordedInputPayload((ProximityState, Call).self, for: .didUpdateProximity)?.first?.0, .near)
        XCTAssertEqual(
            policyA.recordedInputPayload((ProximityState, Call).self, for: .didUpdateProximity)?.first?.1.cId,
            mockCall.cId
        )
    }
}
