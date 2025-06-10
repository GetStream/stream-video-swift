//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless speaker icon button.
public struct StatelessSpeakerIconView: View, Equatable {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    var isEnabled: Bool

    /// The size of the speaker icon.
    public var size: CGFloat

    /// The action handler for the speaker icon button.
    public var actionHandler: ActionHandler?

    /// Initializes a stateless speaker icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the speaker icon.
    ///   - size: The size of the speaker icon.
    ///   - actionHandler: An optional closure to handle button tap actions.

    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.init(
            isEnabled: call?.state.callSettings.speakerOn ?? false,
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
        lhs: StatelessSpeakerIconView,
        rhs: StatelessSpeakerIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    /// The body of the speaker icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: isEnabled
                        ? images.speakerOn
                        : images.speakerOff,
                    size: size,
                    iconStyle: isEnabled
                        ? .primary
                        : .transparent
                )
            }
        )
    }
}
