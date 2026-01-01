//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import StreamVideo

/// An adapter responsible for enforcing the stop of Picture in Picture
/// playback when the application returns to the foreground. It listens
/// to application state and PiP activity changes and stops PiP if the
/// app becomes active.
final class PictureInPictureEnforcedStopAdapter {

    /// Keys used to identify disposable operations.
    private enum DisposableKey: String { case stopEnforceOperation }

    /// Adapter that provides the current application state.
    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.screenProperties) private var screenProperties

    /// A serial dispatch queue for background processing.
    private let processingQueue = DispatchQueue(label: UUID().uuidString)

    /// A bag to store Combine subscriptions for cancellation.
    private let disposableBag = DisposableBag()

    /// Initializes the adapter with a Picture in Picture controller and
    /// starts observing application state and PiP activity to enforce stop.
    ///
    /// - Parameter pictureInPictureController: The PiP controller to manage.
    init(_ pictureInPictureController: StreamPictureInPictureControllerProtocol) {
        Publishers.CombineLatest(
            applicationStateAdapter.statePublisher,
            pictureInPictureController.isPictureInPictureActivePublisher
        )
        .sink {
            [weak self, weak pictureInPictureController] in self?.didUpdate(
                applicationState: $0,
                isPictureInPictureActive: $1,
                pictureInPictureController: pictureInPictureController
            )
        }
        .store(in: disposableBag)
    }

    /// Cleans up all stored subscriptions when the instance is deallocated.
    deinit {
        disposableBag.removeAll()
    }

    /// Handles updates to application state and PiP activity.
    /// Starts a timer that attempts to stop PiP if the app is foregrounded
    /// and PiP is active.
    ///
    /// - Parameters:
    ///   - applicationState: The current state of the application.
    ///   - isPictureInPictureActive: A Boolean indicating whether PiP is active.
    ///   - pictureInPictureController: The PiP controller to manage.
    private func didUpdate(
        applicationState: ApplicationState,
        isPictureInPictureActive: Bool,
        pictureInPictureController: StreamPictureInPictureControllerProtocol?
    ) {
        switch (applicationState, isPictureInPictureActive) {
        case (.foreground, true):
            DefaultTimer
                .publish(every: screenProperties.refreshRate)
                .filter { [weak self] _ in self?.applicationStateAdapter.state == .foreground }
                .log(.debug) { _ in "Will attempt to forcefully stop Picture-in-Picture." }
                .receive(on: DispatchQueue.main)
                .sink { [weak pictureInPictureController] _ in pictureInPictureController?.stopPictureInPicture() }
                .store(in: disposableBag, key: DisposableKey.stopEnforceOperation.rawValue)
        default:
            disposableBag.remove(DisposableKey.stopEnforceOperation.rawValue)
        }
    }
}
