//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import UIKit

/// Manages the state of the Picture-in-Picture window.
///
/// Handles all state changes and provides a reactive interface for observing updates.
final class PictureInPictureStore: ObservableObject, @unchecked Sendable {

    /// The current state of the Picture-in-Picture window.
    struct State: Sendable {
        var isActive: Bool
        var call: Call?
        var sourceView: UIView?
        var viewFactory: PictureInPictureViewFactory
        var content: PictureInPictureContent
        var preferredContentSize: CGSize
        var contentSize: CGSize
        var canStartPictureInPictureAutomaticallyFromInline: Bool

        /// The initial state of the Picture-in-Picture window.
        @MainActor
        static let initial = State(
            isActive: false,
            viewFactory: .init(DefaultViewFactory.shared),
            content: .inactive,
            preferredContentSize: .init(width: 640, height: 480),
            contentSize: .zero,
            canStartPictureInPictureAutomaticallyFromInline: true
        )
    }

    /// Actions that can modify the Picture-in-Picture state.
    enum Action {
        /// Sets whether Picture-in-Picture is currently active.
        case setActive(Bool)
        /// Updates the current call instance.
        case setCall(Call?)
        /// Sets the source view for Picture-in-Picture.
        case setSourceView(UIView?)
        /// Updates the view factory for creating content.
        case setViewFactory(PictureInPictureViewFactory)
        /// Changes the current content being displayed.
        case setContent(PictureInPictureContent)
        /// Sets the preferred size for Picture-in-Picture content.
        case setPreferredContentSize(CGSize)
        /// Updates the actual content size.
        case setContentSize(CGSize)
        /// Controls automatic Picture-in-Picture activation.
        case setCanStartPictureInPictureAutomaticallyFromInline(Bool)
    }

    private let subject: CurrentValueSubject<State, Never>
    var state: State { subject.value }

    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    @MainActor
    init() {
        subject = .init(.initial)
    }

    /// Dispatches an action to modify the state.
    ///
    /// - Parameter action: The action to process
    func dispatch(_ action: Action) {
        processingQueue.addOperation { [weak self] in
            guard let self else {
                return
            }

            var updatedState = state
            switch action {
            case let .setActive(value):
                updatedState.isActive = value
            case let .setCall(value):
                updatedState.call = value
            case let .setSourceView(value):
                updatedState.sourceView = value
            case let .setViewFactory(value):
                updatedState.viewFactory = value
            case let .setContent(value):
                updatedState.content = value
            case let .setPreferredContentSize(value):
                updatedState.preferredContentSize = value
            case let .setContentSize(value):
                updatedState.contentSize = value
            case let .setCanStartPictureInPictureAutomaticallyFromInline(value):
                updatedState.canStartPictureInPictureAutomaticallyFromInline = value
            }

            self.subject.send(updatedState)
        }
    }

    /// Creates a publisher for observing state changes.
    ///
    /// - Parameter keyPath: The state property to observe
    /// - Returns: A publisher that emits values when the specified property changes
    func publisher<Value>(for keyPath: KeyPath<State, Value>) -> AnyPublisher<Value, Never> {
        subject
            .map(keyPath)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
