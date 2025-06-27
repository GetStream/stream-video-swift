//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
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

    /// The size of the participants list button.
    var size: CGFloat

    /// A binding that indicates whether the participants list button is active.
    var isActive: Binding<Bool>

    /// The action handler for the participants list button.
    var actionHandler: ActionHandler?

    var publisher: AnyPublisher<Int, Never>?

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
        self.size = size
        self.isActive = isActive

        count = call?.state.participants.endIndex ?? 0
        publisher = call?
            .state
            .$participants
            .map(\.endIndex)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

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
        .onReceive(publisher) { count = $0 }
    }
}
