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

    private var mockStreamVideo: MockStreamVideo! = .init()
    private var subject: PictureInPictureStore! = .init()
    private var disposableBag: DisposableBag! = .init()

    override func tearDown() async throws {
        subject = nil
        disposableBag = nil
        mockStreamVideo = nil
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

    func test_setActive() async {
        // When
        subject.dispatch(.setActive(true))

        // Then
        await fulfilmentInMainActor { self.subject.state.isActive }
    }

    @MainActor
    func test_setCall() async {
        // Given
        let call = MockCall(.dummy())

        // When
        subject.dispatch(.setCall(call))

        // Then
        await fulfilmentInMainActor { self.subject.state.call?.cId == call.cId }
    }

    @MainActor
    func test_setSourceView() async {
        // Given
        let view = UIView()

        // When
        subject.dispatch(.setSourceView(view))

        // Then
        await fulfilmentInMainActor { self.subject.state.sourceView === view }
    }

    @MainActor
    func test_setViewFactory() async {
        // Given
        let factory = PictureInPictureViewFactory(DefaultViewFactory.shared)

        // When
        subject.dispatch(.setViewFactory(factory))

        // Then
        await fulfilmentInMainActor { self.subject.state.viewFactory === factory }
    }

    @MainActor
    func test_setContent() async {
        // Given
        let call = MockCall(.dummy())
        let participant = CallParticipant.dummy()
        let content = PictureInPictureContent.participant(call, participant, nil)

        // When
        subject.dispatch(.setContent(content))

        // Then
        await fulfilmentInMainActor { self.subject.state.content == content }
    }

    func test_setPreferredContentSize() async {
        // Given
        let size = CGSize(width: 800, height: 600)

        // When
        subject.dispatch(.setPreferredContentSize(size))

        // Then
        await fulfilmentInMainActor { self.subject.state.preferredContentSize == size }
    }

    func test_setContentSize() async {
        // Given
        let size = CGSize(width: 400, height: 300)

        // When
        subject.dispatch(.setContentSize(size))

        // Then
        await fulfilmentInMainActor { self.subject.state.contentSize == size }
    }

    func test_setCanStartPictureInPictureAutomaticallyFromInline() async {
        // When
        subject.dispatch(.setCanStartPictureInPictureAutomaticallyFromInline(false))

        // Then
        await fulfilmentInMainActor { self.subject.state.canStartPictureInPictureAutomaticallyFromInline == false }
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
    func test_multipleActions() async {
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
        await fulfilmentInMainActor { self.subject.state.call?.callId == call.callId }
        await fulfilmentInMainActor { self.subject.state.sourceView == view }
        await fulfilmentInMainActor { self.subject.state.contentSize == size }
        await fulfilmentInMainActor { self.subject.state.isActive }
    }
}
