//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import UIKit

final class PictureInPictureStore: ObservableObject {

    struct State: Sendable {
        var isActive: Bool
        var call: Call?
        var sourceView: UIView?
        var viewFactory: AnyViewFactory
        var content: StreamPictureInPictureContentState
        var preferredContentSize: CGSize
        var contentSize: CGSize
        var canStartPictureInPictureAutomaticallyFromInline: Bool

        static let initial = State(
            isActive: false,
            viewFactory: .init(DefaultViewFactory.shared),
            content: .inactive,
            preferredContentSize: .init(width: 640, height: 480),
            contentSize: .zero,
            canStartPictureInPictureAutomaticallyFromInline: true
        )
    }

    enum Action {
        case setActive(Bool)
        case setCall(Call?)
        case setSourceView(UIView?)
        case setViewFactory(AnyViewFactory)
        case setContent(StreamPictureInPictureContentState)
        case setPreferredContentSize(CGSize)
        case setContentSize(CGSize)
        case setCanStartPictureInPictureAutomaticallyFromInline(Bool)
    }

    private let subject: CurrentValueSubject<State, Never> = .init(.initial)
    var state: State { subject.value }

    private let processingQueue = UnfairQueue()

    func dispatch(_ action: Action) {
        processingQueue.sync { [weak self] in
            guard let self else {
                return
            }

            var currentState = state
            switch action {
            case let .setActive(value):
                currentState.isActive = value
            case let .setCall(value):
                currentState.call = value
            case let .setSourceView(value):
                currentState.sourceView = value
            case let .setViewFactory(value):
                currentState.viewFactory = value
            case let .setContent(value):
                currentState.content = value
            case let .setPreferredContentSize(value):
                currentState.preferredContentSize = value
            case let .setContentSize(value):
                currentState.contentSize = value
            case let .setCanStartPictureInPictureAutomaticallyFromInline(value):
                currentState.canStartPictureInPictureAutomaticallyFromInline = value
            }

            self.subject.send(currentState)
        }
    }

    func publisher<Value>(for keyPath: KeyPath<State, Value>) -> AnyPublisher<Value, Never> {
        subject
            .map(keyPath)
            .eraseToAnyPublisher()
    }
}
