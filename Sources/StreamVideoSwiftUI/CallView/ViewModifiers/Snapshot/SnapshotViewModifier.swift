//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

struct SnapshotViewContainer<Content: View>: UIViewRepresentable {

    typealias UIViewType = UIView

    @MainActor
    final class SnapshotViewContainerCoordinator {
        private var trigger: SnapshotTriggering
        private let snapshotHandler: (UIImage) -> Void
        private var cancellable: AnyCancellable?

        weak var content: UIViewType? {
            didSet { captureSnapshot() }
        }

        init(
            trigger: SnapshotTriggering,
            snapshotHandler: @escaping (UIImage) -> Void
        ) {
            self.trigger = trigger
            self.snapshotHandler = snapshotHandler

            cancellable = trigger
                .publisher
                .removeDuplicates()
                .sink { [weak self] triggered in
                    guard triggered == true else { return }
                    self?.captureSnapshot()
                }
        }

        private func captureSnapshot() {
            defer { trigger.binding.wrappedValue = false }
            guard let content, trigger.binding.wrappedValue == true else { return }
            snapshotHandler(content.snapshot())
        }
    }

    private let trigger: SnapshotTriggering
    private let snapshotHandler: (UIImage) -> Void
    let contentProvider: () -> Content

    init(
        trigger: SnapshotTriggering,
        snapshotHandler: @escaping (UIImage) -> Void,
        @ViewBuilder contentProvider: @escaping () -> Content
    ) {
        self.trigger = trigger
        self.snapshotHandler = snapshotHandler
        self.contentProvider = contentProvider
    }

    func makeUIView(
        context: Context
    ) -> UIViewType {
        let viewController = UIHostingController(rootView: contentProvider())
        context.coordinator.content = viewController.view
        return viewController.view
    }

    func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        context.coordinator.content = uiView
    }

    func makeCoordinator() -> SnapshotViewContainerCoordinator {
        SnapshotViewContainerCoordinator(
            trigger: trigger,
            snapshotHandler: snapshotHandler
        )
    }
}

@MainActor
struct SnapshotViewModifier: ViewModifier {

    var trigger: SnapshotTriggering
    var snapshotHandler: (UIImage) -> Void

    func body(content: Content) -> some View {
        SnapshotViewContainer(
            trigger: trigger,
            snapshotHandler: snapshotHandler
        ) {
            GeometryReader { proxy in
                content
                    .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
            }
        }
    }
}

public protocol SnapshotTriggering {

    var binding: Binding<Bool> { get set }

    var publisher: AnyPublisher<Bool, Never> { get }

    func capture()
}

extension View {

    @ViewBuilder
    public func snapshot(
        trigger: SnapshotTriggering,
        snapshotHandler: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(
            SnapshotViewModifier(
                trigger: trigger,
                snapshotHandler: snapshotHandler
            )
        )
    }
}
