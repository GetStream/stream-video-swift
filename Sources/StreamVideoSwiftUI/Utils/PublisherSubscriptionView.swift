//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI

/// A SwiftUI view that subscribes to a `Publisher` and renders its value
/// using a provided content builder. Optimized for performance in complex
/// and deeply nested view hierarchies by tightly scoping state updates.
///
/// ## Why Use `PublisherSubscriptionView`
///
/// This view provides **significant performance advantages** over traditional
/// SwiftUI observation mechanisms:
///
/// - **No full-body invalidation:** Avoids recomputing the entire `.body`
///   whenever the publisher emits a new value (unlike `.onReceive`).
/// - **Isolated updates:** Localizes recomputation to only the view
///   returned by the `contentProvider`, rather than the entire parent view
///   or view hierarchy (as with `@ObservedObject` or `@StateObject`).
/// - **Minimal overhead:** Avoids the propagation chains and unnecessary
///   recomputation introduced by `Binding` usage in deep hierarchies.
/// - **Cleaner architecture:** Decouples state updates from SwiftUI view
///   identity, avoiding edge cases related to view reconstruction.
///
/// Use `PublisherSubscriptionView` when you need to render a value from a
/// `Publisher` inside a SwiftUI view hierarchy, especially when minimizing
/// rendering cost and view body invalidation is critical.
public struct PublisherSubscriptionView<Value: Equatable, Content: View>: View {

    /// Internal observable object used to drive updates from the provided
    /// publisher. It removes duplicate values and ensures delivery on the
    /// main queue.
    final class ViewModel: ObservableObject, @unchecked Sendable {

        @Published private(set) var value: Value
        private var cancellable: AnyCancellable?

        init(
            initial: Value,
            publisher: AnyPublisher<Value, Never>?
        ) {
            value = initial
            cancellable = publisher?
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: \.value, onWeak: self)
        }
    }

    /// Internal SwiftUI view implementation for iOS 14+, using `@StateObject`
    /// to retain and observe the `ViewModel`.
    @available(iOS 14.0, *)
    struct _PublisherSubscriptionView: View {

        @StateObject private var viewModel: ViewModel
        @ViewBuilder private var contentProvider: (Value) -> Content

        init(
            viewModel: ViewModel,
            @ViewBuilder contentProvider: @escaping (Value) -> Content
        ) {
            _viewModel = .init(wrappedValue: viewModel)
            self.contentProvider = contentProvider
        }

        var body: some View {
            contentProvider(viewModel.value)
        }
    }

    /// Internal SwiftUI view implementation for iOS 13, using `@BackportStateObject`
    /// to simulate `@StateObject` behavior in older OS versions.
    @available(iOS 13.0, *)
    struct _BackportPublisherSubscriptionView: View {

        @BackportStateObject private var viewModel: ViewModel
        @ViewBuilder private var contentProvider: (Value) -> Content

        init(
            viewModel: ViewModel,
            @ViewBuilder contentProvider: @escaping (Value) -> Content
        ) {
            _viewModel = .init(wrappedValue: viewModel)
            self.contentProvider = contentProvider
        }

        var body: some View {
            contentProvider(viewModel.value)
        }
    }

    private let viewModel: ViewModel
    @ViewBuilder private var contentProvider: (Value) -> Content

    /// Creates a `PublisherSubscriptionView` with an initial value, a
    /// publisher, and a content builder closure.
    ///
    /// - Parameters:
    ///   - initial: The initial value used before the publisher emits.
    ///   - publisher: The publisher providing updates.
    ///   - contentProvider: A closure that takes the current value and
    ///     returns a SwiftUI view.
    public init(
        initial: Value,
        publisher: AnyPublisher<Value, Never>?,
        @ViewBuilder contentProvider: @escaping (Value) -> Content
    ) {
        viewModel = .init(initial: initial, publisher: publisher)
        self.contentProvider = contentProvider
    }

    /// Returns the appropriate internal view for the current OS version.
    /// Uses `_PublisherSubscriptionView` for iOS 14+, otherwise falls back
    /// to `_BackportPublisherSubscriptionView`.
    public var body: some View {
        if #available(iOS 14.0, *) {
            _PublisherSubscriptionView(
                viewModel: viewModel,
                contentProvider: contentProvider
            )
        } else {
            _BackportPublisherSubscriptionView(
                viewModel: viewModel,
                contentProvider: contentProvider
            )
        }
    }
}
