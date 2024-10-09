//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

private struct LocalParticipantMirroringViewModifier: ViewModifier {

    /// Injects the StreamVideo instance from the environment to access the current active call and its state.
    @Injected(\.streamVideo) private var streamVideo

    /// The participant whose view might need to be mirrored.
    var participant: CallParticipant

    /// The angle by which the content should be rotated if mirroring is applied.
    var angle: Angle

    /// The axis around which the content will be rotated in 3D space.
    var axis: (x: CGFloat, y: CGFloat, z: CGFloat)

    /// Defines the body of the view modifier.
    /// - Parameter content: The content view that is being modified.
    /// - Returns: A view that is conditionally mirrored if the participant is the local participant.
    func body(content: Content) -> some View {
        // If the participant is the local participant, apply a 3D rotation to mirror their view.
        if participant.id == streamVideo.state.activeCall?.state.localParticipant?.id {
            content.rotation3DEffect(angle, axis: axis)
        } else {
            // Otherwise, display the content without modification.
            content
        }
    }
}

extension View {

    /// Applies a mirroring effect to the view if the provided participant is the local participant.
    /// This is useful for displaying the local participant's video feed with a mirror effect in the UI.
    /// - Parameters:
    ///   - participant: The `CallParticipant` that might need to be mirrored.
    ///   - angle: The rotation angle (default is 180 degrees).
    ///   - axis: The axis of rotation (default is around the Y-axis).
    /// - Returns: A view that conditionally applies the mirroring effect.
    public func localParticipantMirroring(
        participant: CallParticipant,
        angle: Angle = .degrees(180),
        axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (x: 0, y: 1, z: 0)
    ) -> some View {
        // Apply the LocalParticipantMirroringViewModifier with the specified participant, angle, and axis.
        modifier(
            LocalParticipantMirroringViewModifier(
                participant: participant,
                angle: angle,
                axis: axis
            )
        )
    }
}
