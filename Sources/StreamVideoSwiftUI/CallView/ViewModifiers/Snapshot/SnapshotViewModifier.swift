//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// Represents a SwiftUI `UIViewRepresentable` struct that encapsulates a UIKit-based view and
/// manages snapshot capturing based on a `SnapshotTriggering` object.
struct SnapshotViewContainer<Content: View>: UIViewRepresentable {

    typealias UIViewType = UIView

    /// A coordinator class that manages snapshot triggering and handling within the
    /// `SnapshotViewContainer`.
    final class SnapshotViewContainerCoordinator: @unchecked Sendable {
        private var trigger: SnapshotTriggering
        private let snapshotHandler: @Sendable (UIImage) -> Void
        private var cancellable: AnyCancellable?
        private let disposableBag = DisposableBag()

        /// Weak reference to the contained `UIView`.
        nonisolated(unsafe) weak var content: UIViewType? {
            didSet { Task { @MainActor in captureSnapshot() } }
        }

        /// Initializes a new `SnapshotViewContainerCoordinator` with the provided trigger and
        ///  snapshot handler.
        /// - Parameters:
        ///   - trigger: The `SnapshotTriggering` object responsible for triggering snapshot
        ///   events.
        ///   - snapshotHandler: A closure that handles the captured `UIImage` from snapshots.
        init(trigger: SnapshotTriggering, snapshotHandler: @escaping @Sendable (UIImage) -> Void) {
            self.trigger = trigger
            self.snapshotHandler = snapshotHandler

            // Set up publisher to capture snapshots based on trigger events
            cancellable = trigger.publisher
                .removeDuplicates()
                .sinkTask(storeIn: disposableBag) { @MainActor [weak self] triggered in
                    guard triggered == true else { return }
                    self?.captureSnapshot()
                }
        }

        /// Captures a snapshot of the current content if trigger is true.
        @MainActor
        private func captureSnapshot() {
            defer { trigger.binding.wrappedValue = false }
            guard let content = content, trigger.binding.wrappedValue == true else { return }
            snapshotHandler(content.snapshot())
        }
    }

    private let trigger: SnapshotTriggering
    private let snapshotHandler: @Sendable (UIImage) -> Void
    let contentProvider: () -> Content

    /// Initializes a new `SnapshotViewContainer` with the specified trigger, snapshot handler, and
    /// content provider.
    /// - Parameters:
    ///   - trigger: The `SnapshotTriggering` object responsible for triggering snapshot events.
    ///   - snapshotHandler: A closure that handles the captured `UIImage` from snapshots.
    ///   - contentProvider: A closure that provides the SwiftUI `View` content to be
    ///   encapsulated in a UIKit view.
    init(
        trigger: SnapshotTriggering,
        snapshotHandler: @escaping @Sendable (UIImage) -> Void,
        @ViewBuilder contentProvider: @escaping () -> Content
    ) {
        self.trigger = trigger
        self.snapshotHandler = snapshotHandler
        self.contentProvider = contentProvider
    }

    /// Creates the underlying `UIKit` view (a `UIView`) managed by the coordinator.
    func makeUIView(context: Context) -> UIViewType {
        let viewController = UIHostingController(rootView: contentProvider())
        context.coordinator.content = viewController.view
        return viewController.view
    }

    /// Updates the existing `UIKit` view with new context.
    func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.content = uiView
    }

    /// Creates a coordinator instance to manage snapshot events within the `SnapshotViewContainer`.
    func makeCoordinator() -> SnapshotViewContainerCoordinator {
        SnapshotViewContainerCoordinator(trigger: trigger, snapshotHandler: snapshotHandler)
    }
}

/// A `ViewModifier` that applies the `SnapshotViewContainer` within a SwiftUI view hierarchy.
struct SnapshotViewModifier: ViewModifier {

    var trigger: SnapshotTriggering
    var snapshotHandler: @Sendable (UIImage) -> Void

    /// Applies the `SnapshotViewContainer` with the specified trigger and snapshot handler to the
    /// provided content.
    /// - Parameter content: The SwiftUI view content to apply the snapshot capability.
    /// - Returns: A modified view with the `SnapshotViewContainer` functionality.
    func body(content: Content) -> some View {
        SnapshotViewContainer(trigger: trigger, snapshotHandler: snapshotHandler) {
            GeometryReader { proxy in
                content
                    .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
            }
        }
    }
}

/// A protocol defining requirements for objects that can trigger snapshot captures.
public protocol SnapshotTriggering {

    /// The binding used to trigger snapshot events.
    var binding: Binding<Bool> { get set }

    /// A publisher that emits `Bool` values to trigger snapshot events.
    var publisher: AnyPublisher<Bool, Never> { get }

    /// Manually triggers a snapshot capture.
    func capture()
}

extension View {

    /// Adds a snapshot capability to the view using the specified trigger and snapshot handler.
    /// - Parameters:
    ///   - trigger: The `SnapshotTriggering` object responsible for triggering snapshot events.
    ///   - snapshotHandler: A closure that handles the captured `UIImage` from snapshots.
    /// - Returns: A modified view with snapshot capability.
    @ViewBuilder
    public func snapshot(
        trigger: SnapshotTriggering,
        snapshotHandler: @escaping @Sendable (UIImage) -> Void
    ) -> some View {
        modifier(
            SnapshotViewModifier(
                trigger: trigger,
                snapshotHandler: snapshotHandler
            )
        )
    }
}
