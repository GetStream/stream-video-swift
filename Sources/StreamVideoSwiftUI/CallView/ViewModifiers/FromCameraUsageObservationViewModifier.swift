//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

private struct FromCameraUsageObservationViewModifier: ViewModifier {

    /// Injects the StreamVideo instance from the environment to access the current active call and its state.
    @Injected(\.streamVideo) private var streamVideo

    /// Tracks whether the front camera is being used by the local user.
    @State var isUsingFrontCameraForLocalUser: Bool = false

    /// The current call whose state is being observed for camera settings.
    var call: Call?

    /// The participant whose view might need to observe front camera usage.
    var participant: CallParticipant

    /// Defines the body of the view modifier.
    /// - Parameter content: The content view that is being modified.
    /// - Returns: A view that updates its state based on the camera position of the local user.
    func body(content: Content) -> some View {
        if participant.id == streamVideo.state.activeCall?.state.localParticipant?.id {
            content
                // Observes changes to the call's settings and updates the `isUsingFrontCameraForLocalUser` state accordingly.
                .onReceive(call?.state.$callSettings) {
                    self.isUsingFrontCameraForLocalUser = $0.cameraPosition == .front
                }
        } else {
            content
        }
    }
}

extension View {

    /// Observes whether the front camera is being used by the local user during a call.
    /// This modifier listens for updates to the camera settings in the call and updates the view.
    /// - Parameters:
    ///   - call: The `Call` instance whose camera settings are being observed.
    ///   - participant: The `CallParticipant` that might need to observe from camera usage.
    /// - Returns: A view that reflects changes based on the front camera usage.
    @ViewBuilder
    public func frontCameraUsageObservation(
        call: Call?,
        participant: CallParticipant
    ) -> some View {
        // Applies the FromCameraUsageObservationViewModifier to observe the camera usage.
        modifier(
            FromCameraUsageObservationViewModifier(
                call: call,
                participant: participant
            )
        )
    }
}
