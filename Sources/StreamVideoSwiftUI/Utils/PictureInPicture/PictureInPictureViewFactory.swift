//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A factory class responsible for creating Picture-in-Picture (PiP) views for video
/// call participants.
///
/// This factory provides a way to create consistent participant image views that can
/// be used in Picture-in-Picture mode. It encapsulates the view creation logic and
/// ensures thread safety with `@unchecked Sendable` conformance.
final class PictureInPictureViewFactory: @unchecked Sendable {

    let source: any ViewFactory

    private let _makeParticipantImageView: (CallParticipant) -> AnyView

    /// Creates a new instance of `PictureInPictureViewFactory`.
    ///
    /// - Parameter viewFactory: A view factory that conforms to the `ViewFactory`
    ///   protocol, used to create the participant image views.
    @MainActor
    init<Factory: ViewFactory>(_ viewFactory: Factory) {
        source = viewFactory
        _makeParticipantImageView = {
            AnyView(
                CallParticipantImageView(
                    viewFactory: viewFactory,
                    id: $0.id,
                    name: $0.name,
                    imageURL: $0.profileImageURL
                )
            )
        }
    }

    /// Creates a view for displaying a participant's image in Picture-in-Picture
    /// mode.
    ///
    /// - Parameter participant: The call participant for whom to create the image
    ///   view.
    /// - Returns: A SwiftUI view displaying the participant's image.
    @ViewBuilder
    func makeParticipantImageView(
        participant: CallParticipant
    ) -> some View {
        _makeParticipantImageView(participant)
    }
}
