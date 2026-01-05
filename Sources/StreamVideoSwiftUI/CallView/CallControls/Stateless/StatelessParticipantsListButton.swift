//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless participants list button.
public struct StatelessParticipantsListButton: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    /// The associated call for the participants list button.
    public weak var call: Call?

    /// The size of the participants list button.
    public var size: CGFloat

    /// A binding that indicates whether the participants list button is active.
    public var isActive: Binding<Bool>

    /// The action handler for the participants list button.
    public var actionHandler: ActionHandler?

    @State private var count: Int

    /// Initializes a stateless participants list button view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the participants list button.
    ///   - size: The size of the participants list button.
    ///   - isActive: A binding that indicates whether the button is active.
    ///   - actionHandler: An optional closure to handle button tap actions.
    @MainActor
    public init(
        call: Call?,
        size: CGFloat = 44,
        isActive: Binding<Bool>,
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        self.isActive = isActive
        _count = .init(initialValue: call?.state.participants.endIndex ?? 0)
        self.actionHandler = actionHandler
    }

    /// The body of the participants list button view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: images.participantsIcon,
                    size: size,
                    iconStyle: isActive.wrappedValue ? .secondaryActive : .secondary
                )
            }
        )
        .overlay(
            ControlBadgeView("\(count)")
                .opacity(count > 1 ? 1 : 0)
        )
        .accessibility(identifier: "participantMenu")
        .onReceive(call?.state.$participants) {
            // Update the count based on the number of participants in the call.
            count = $0.endIndex
        }
    }
}
