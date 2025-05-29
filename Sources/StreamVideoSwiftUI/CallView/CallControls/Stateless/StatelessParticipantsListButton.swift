//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

extension Publishers {
    /// Creates a CombineLatest publisher from two optional publishers.
    /// If either is nil, returns an Empty publisher.
    public static func combineLatest<A, B>(
        _ a: AnyPublisher<A, Never>?,
        _ b: AnyPublisher<B, Never>?
    ) -> AnyPublisher<(A, B), Never> {
        guard let a, let b else {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }
        return a.combineLatest(b).eraseToAnyPublisher()
    }

    /// Creates a CombineLatest publisher from three optional publishers.
    /// If either is nil, returns an Empty publisher.
    public static func combineLatest<A, B, C>(
        _ a: AnyPublisher<A, Never>?,
        _ b: AnyPublisher<B, Never>?,
        _ c: AnyPublisher<C, Never>?,
    ) -> AnyPublisher<(A, B, C), Never> {
        guard let a, let b, let c else {
            return Empty(completeImmediately: true).eraseToAnyPublisher()
        }
        return Publishers.CombineLatest3(a, b, c).eraseToAnyPublisher()
    }
}

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
        self.actionHandler = actionHandler
    }

    /// The body of the participants list button view.
    public var body: some View {
        PublisherSubscriptionView(
            initial: call?.state.participants.endIndex ?? 0,
            publisher: call?.state.$participants.map(\.endIndex).eraseToAnyPublisher()
        ) { count in
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
        }
    }
}
