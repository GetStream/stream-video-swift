//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless hang-up icon button.
public struct StatelessHangUpIconView: View, Equatable {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The size of the hang-up icon.
    public var size: CGFloat

    /// The action handler for the hang-up icon button.
    public var actionHandler: ActionHandler?

    /// Initializes a stateless hang-up icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the hang-up icon.
    ///   - size: The size of the hang-up icon.
    ///   - actionHandler: An optional closure to handle button tap actions.

    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.init(size: size, actionHandler: actionHandler)
    }

    public init(
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.size = size

        self.actionHandler = actionHandler
    }

    nonisolated public static func == (
        lhs: StatelessHangUpIconView,
        rhs: StatelessHangUpIconView
    ) -> Bool {
        lhs.size == rhs.size
    }

    /// The body of the hang-up icon view.
    public var body: some View {
        Button { actionHandler?() } label: {
            CallIconView(
                icon: images.hangup,
                size: size,
                iconStyle: .destructive
            )
        }
        .accessibility(identifier: "hangUp")
    }
}
