//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

@MainActor
final class PictureInPictureStoreTests: XCTestCase, @unchecked Sendable {

    private var subject: PictureInPictureStore! = .init()
    private var disposableBag: DisposableBag! = .init()

    override func tearDown() async throws {
        subject = nil
        disposableBag = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState() {
        XCTAssertFalse(subject.state.isActive)
        XCTAssertNil(subject.state.call)
        XCTAssertNil(subject.state.sourceView)
        XCTAssertEqual(subject.state.content, .inactive)
        XCTAssertEqual(subject.state.preferredContentSize, CGSize(width: 640, height: 480))
        XCTAssertEqual(subject.state.contentSize, .zero)
        XCTAssertTrue(subject.state.canStartPictureInPictureAutomaticallyFromInline)
    }

    // MARK: - Action Tests

    func test_setActive() {
        // When
        subject.dispatch(.setActive(true))

        // Then
        XCTAssertTrue(subject.state.isActive)
    }

    @MainActor
    func test_setCall() {
        // Given
        let call = MockCall(.dummy())

        // When
        subject.dispatch(.setCall(call))

        // Then
        XCTAssertEqual(subject.state.call?.cId, call.cId)
    }

    @MainActor
    func test_setSourceView() {
        // Given
        let view = UIView()

        // When
        subject.dispatch(.setSourceView(view))

        // Then
        XCTAssertTrue(subject.state.sourceView === view)
    }

    @MainActor
    func test_setViewFactory() {
        // Given
        let factory = PictureInPictureViewFactory(DefaultViewFactory.shared)

        // When
        subject.dispatch(.setViewFactory(factory))

        // Then
        XCTAssertTrue(subject.state.viewFactory === factory)
    }

    @MainActor
    func test_setContent() {
        // Given
        let call = MockCall(.dummy())
        let participant = CallParticipant.dummy()
        let content = PictureInPictureContent.participant(call, participant, nil)

        // When
        subject.dispatch(.setContent(content))

        // Then
        XCTAssertEqual(subject.state.content, content)
    }

    func test_setPreferredContentSize() {
        // Given
        let size = CGSize(width: 800, height: 600)

        // When
        subject.dispatch(.setPreferredContentSize(size))

        // Then
        XCTAssertEqual(subject.state.preferredContentSize, size)
    }

    func test_setContentSize() {
        // Given
        let size = CGSize(width: 400, height: 300)

        // When
        subject.dispatch(.setContentSize(size))

        // Then
        XCTAssertEqual(subject.state.contentSize, size)
    }

    func test_setCanStartPictureInPictureAutomaticallyFromInline() {
        // When
        subject.dispatch(.setCanStartPictureInPictureAutomaticallyFromInline(false))

        // Then
        XCTAssertFalse(subject.state.canStartPictureInPictureAutomaticallyFromInline)
    }

    // MARK: - Publisher Tests

    func test_publisher_emitsInitialValue() async throws {
        let expected = subject.state.isActive

        // When
        let actual = try await subject
            .publisher(for: \.isActive)
            .nextValue(timeout: defaultTimeout)

        XCTAssertEqual(actual, expected)
    }

    func test_publisher_emitsUpdates() async {
        let expectation = expectation(description: "Publisher emits updates")
        expectation.expectedFulfillmentCount = 2

        var values: [Bool] = []

        // When
        subject.publisher(for: \.isActive)
            .sink { value in
                values.append(value)
                expectation.fulfill()
            }
            .store(in: disposableBag)

        subject.dispatch(.setActive(true))

        // Then
        await fulfillment(of: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(values, [false, true])
    }

    @MainActor
    func test_multipleActions() {
        // Given
        let call = MockCall(.dummy())
        let view = UIView()
        let size = CGSize(width: 800, height: 600)

        // When
        subject.dispatch(.setCall(call))
        subject.dispatch(.setSourceView(view))
        subject.dispatch(.setContentSize(size))
        subject.dispatch(.setActive(true))

        // Then
        XCTAssertEqual(subject.state.call?.callId, call.callId)
        XCTAssertEqual(subject.state.sourceView, view)
        XCTAssertEqual(subject.state.contentSize, size)
        XCTAssertTrue(subject.state.isActive)
    }
}
