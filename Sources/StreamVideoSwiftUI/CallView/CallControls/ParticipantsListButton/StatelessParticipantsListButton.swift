//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless participants list button.
public struct StatelessParticipantsListButton: View, Equatable {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    /// The size of the participants list button.
    public var size: CGFloat

    /// A binding that indicates whether the participants list button is active.
    public var isActive: Binding<Bool>

    /// The action handler for the participants list button.
    public var actionHandler: ActionHandler?

    private var count: Int

    /// Initializes a stateless participants list button view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the participants list button.
    ///   - size: The size of the participants list button.
    ///   - isActive: A binding that indicates whether the button is active.
    ///   - actionHandler: An optional closure to handle button tap actions.

    public init(
        call: Call?,
        size: CGFloat = 44,
        isActive: Binding<Bool>,
        actionHandler: ActionHandler? = nil
    ) {
        self.init(
            count: call?.state.participants.endIndex ?? 0,
            size: size,
            isActive: isActive,
            actionHandler: actionHandler
        )
    }

    init(
        count: Int,
        size: CGFloat = 44,
        isActive: Binding<Bool>,
        actionHandler: ActionHandler? = nil
    ) {
        self.count = count
        self.size = size
        self.isActive = isActive

        self.actionHandler = actionHandler
    }

    nonisolated public static func == (
        lhs: StatelessParticipantsListButton,
        rhs: StatelessParticipantsListButton
    ) -> Bool {
        lhs.size == rhs.size
            && lhs.isActive.wrappedValue == rhs.isActive.wrappedValue
            && lhs.count == rhs.count
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
                .equatable()
                .opacity(count > 1 ? 1 : 0)
        )
        .accessibility(identifier: "participantMenu")
    }
}
