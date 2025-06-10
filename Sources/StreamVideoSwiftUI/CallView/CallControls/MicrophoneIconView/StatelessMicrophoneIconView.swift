//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless microphone icon button.
public struct StatelessMicrophoneIconView: View, Equatable {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    var isEnabled: Bool

    /// The size of the microphone icon.
    public var size: CGFloat

    /// The action handler for the microphone icon button.
    public var actionHandler: ActionHandler?

    /// Initializes a stateless microphone icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the microphone icon.
    ///   - size: The size of the microphone icon.
    ///   - actionHandler: An optional closure to handle button tap actions.

    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.init(
            isEnabled: call?.state.callSettings.audioOn ?? false,
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
        lhs: StatelessMicrophoneIconView,
        rhs: StatelessMicrophoneIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    /// The body of the microphone icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: isEnabled
                        ? images.micTurnOn
                        : images.micTurnOff,
                    size: size,
                    iconStyle: isEnabled
                        ? .transparent
                        : .disabled
                )
            }
        )
        .accessibility(identifier: "microphoneToggle")
        .streamAccessibility(value: isEnabled ? "1" : "0")
    }
}
