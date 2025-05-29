//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless toggle camera icon button.
public struct StatelessToggleCameraIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The associated call for the toggle camera icon.
    public weak var call: Call?

    /// The size of the toggle camera icon.
    public var size: CGFloat

    /// The action handler for the toggle camera icon button.
    public var actionHandler: ActionHandler?

    /// Initializes a stateless toggle camera icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the toggle camera icon.
    ///   - size: The size of the toggle camera icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        self.actionHandler = actionHandler
    }

    /// The body of the toggle camera icon view.
    public var body: some View {
        PublisherSubscriptionView(
            initial: call?.state.callSettings.cameraPosition ?? .front,
            publisher: call?.state.$callSettings.compactMap { $0.cameraPosition }.eraseToAnyPublisher()
        ) { cameraPosition in
            Button(
                action: { actionHandler?() },
                label: {
                    CallIconView(
                        icon: images.toggleCamera,
                        size: size,
                        iconStyle: .secondary
                    )
                }
            )
            .accessibility(identifier: "cameraPositionToggle")
            .streamAccessibility(value: cameraPosition == .front ? "1" : "0")
        }
    }
}
