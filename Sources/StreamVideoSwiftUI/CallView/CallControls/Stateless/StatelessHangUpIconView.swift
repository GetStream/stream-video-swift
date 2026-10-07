//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless hang-up icon button.
public struct StatelessHangUpIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The associated call for the hang-up icon.
    public weak var call: Call?

    /// The size of the hang-up icon.
    public var size: CGFloat

    /// The action handler for the hang-up icon button.
    public var actionHandler: ActionHandler?

    @ObservedObject private var callSettings: CallSettings

    /// Initializes a stateless hang-up icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the hang-up icon.
    ///   - size: The size of the hang-up icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    @MainActor
    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        _callSettings = .init(wrappedValue: call?.state.callSettings ?? .init())
        self.actionHandler = actionHandler
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
