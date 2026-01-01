//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine

/// A wrapper around AVPictureInPictureControllerDelegate that publishes all
/// delegate method calls via a single Combine publisher.
final class PictureInPictureDelegateProxy: NSObject, AVPictureInPictureControllerDelegate {

    /// Enum representing each AVPictureInPictureControllerDelegate method call
    /// with its respective associated values.
    enum Event: CustomStringConvertible {
        case willStart(AVPictureInPictureController)
        case didStart(AVPictureInPictureController)
        case failedToStart(AVPictureInPictureController, Error)
        case willStop(AVPictureInPictureController)
        case didStop(AVPictureInPictureController)
        case restoreUI(AVPictureInPictureController, (Bool) -> Void)

        var description: String {
            switch self {
            case let .willStart(controller):
                return ".willStart(controller: \(controller))"
            case let .didStart(controller):
                return ".didStart(controller: \(controller))"
            case let .failedToStart(controller, error):
                return ".failedToStart(controller: \(controller), error: \(error))"
            case let .willStop(controller):
                return ".willStop(controller: \(controller))"
            case let .didStop(controller):
                return ".didStop(controller: \(controller))"
            case let .restoreUI(controller, _):
                return ".restoreUI(controller: \(controller), completionHandler: (closure))"
            }
        }
    }

    /// The Combine publisher that emits Picture-in-Picture delegate events.
    var publisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private let eventSubject = PassthroughSubject<Event, Never>()

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        eventSubject.send(.willStart(pictureInPictureController))
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        eventSubject.send(.didStart(pictureInPictureController))
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        eventSubject.send(.failedToStart(pictureInPictureController, error))
    }

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        eventSubject.send(.willStop(pictureInPictureController))
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        eventSubject.send(.didStop(pictureInPictureController))
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        eventSubject.send(.restoreUI(pictureInPictureController, completionHandler))
    }
}
