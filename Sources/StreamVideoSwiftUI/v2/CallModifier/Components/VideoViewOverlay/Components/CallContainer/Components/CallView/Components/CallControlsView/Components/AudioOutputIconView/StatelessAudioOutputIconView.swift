//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless audio output icon button.
public struct StatelessAudioOutputIconView: View, Equatable {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    var isEnabled: Bool

    /// The size of the audio output icon.
    public var size: CGFloat

    /// The action handler for the audio output icon button.
    public var actionHandler: ActionHandler?

    /// Initializes a stateless audio output icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the audio output icon.
    ///   - size: The size of the audio output icon.
    ///   - actionHandler: An optional closure to handle button tap actions.

    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.init(
            isEnabled: call?.state.callSettings.audioOutputOn ?? true,
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
        lhs: StatelessAudioOutputIconView,
        rhs: StatelessAudioOutputIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    /// The body of the audio output icon view.
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
