//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless speaker icon button.
public struct StatelessSpeakerIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The associated call for the speaker icon.
    public weak var call: Call?

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
    @MainActor
    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        self.actionHandler = actionHandler
    }

    /// The body of the speaker icon view.
    public var body: some View {
        PublisherSubscriptionView(
            initial: call?.state.callSettings.speakerOn ?? false,
            publisher: call?.state.$callSettings.compactMap(\.speakerOn).eraseToAnyPublisher()
        ) { isActive in
            Button(
                action: { actionHandler?() },
                label: {
                    CallIconView(
                        icon: isActive
                            ? images.speakerOn
                            : images.speakerOff,
                        size: size,
                        iconStyle: isActive
                            ? .primary
                            : .transparent
                    )
                }
            )
        }
    }
}
