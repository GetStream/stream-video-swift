//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless video icon button.
public struct StatelessVideoIconView: View, Equatable {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    var isEnabled: Bool

    /// The size of the video icon.
    public var size: CGFloat

    /// The action handler for the video icon button.
    public var actionHandler: ActionHandler?

    /// Initializes a stateless video icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the video icon.
    ///   - size: The size of the video icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.init(
            isEnabled: call?.state.callSettings.videoOn ?? false,
            size: size,
            actionHandler: actionHandler
        )
    }

    init(
        isEnabled: Bool,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.isEnabled = isEnabled
        self.size = size

        self.actionHandler = actionHandler
    }

    nonisolated public static func == (
        lhs: StatelessVideoIconView,
        rhs: StatelessVideoIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    /// The body of the video icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: isEnabled
                        ? images.videoTurnOn
                        : images.videoTurnOff,
                    size: size,
                    iconStyle: isEnabled
                        ? .transparent
                        : .disabled
                )
            }
        )
        .accessibility(identifier: "cameraToggle")
        .streamAccessibility(value: isEnabled ? "1" : "0")
    }
}
