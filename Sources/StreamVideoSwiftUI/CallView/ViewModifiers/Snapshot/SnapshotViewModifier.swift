//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

struct SnapshotViewContainer<Content: View>: UIViewControllerRepresentable {

    typealias UIViewControllerType = UIViewController

    @MainActor
    final class SnapshotViewContainerCoordinator {
        private let snapshotHandler: (UIImage) -> Void
        private var captureTrigger: AnyPublisher<Bool, Never>
        private var cancellable: AnyCancellable?

        weak var content: UIViewControllerType?

        init(
            captureTrigger: AnyPublisher<Bool, Never>,
            snapshotHandler: @escaping (UIImage) -> Void
        ) {
            self.captureTrigger = captureTrigger
            self.snapshotHandler = snapshotHandler
            cancellable = captureTrigger
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didUpdateCaptureSnapshot($0) }
        }

        deinit {
            cancellable?.cancel()
        }

        private func didUpdateCaptureSnapshot(_ newValue: Bool) {
            guard
                newValue,
                let content = content
            else {
                return
            }

            snapshotHandler(content.view.snapshot())
        }
    }

    private let captureTrigger: AnyPublisher<Bool, Never>
    private let snapshotHandler: (UIImage) -> Void
    let contentProvider: () -> Content

    init(
        captureTrigger: AnyPublisher<Bool, Never>,
        snapshotHandler: @escaping (UIImage) -> Void,
        @ViewBuilder contentProvider: @escaping () -> Content
    ) {
        self.captureTrigger = captureTrigger
        self.snapshotHandler = snapshotHandler
        self.contentProvider = contentProvider
    }

    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIHostingController(rootView: contentProvider())
        context.coordinator.content = viewController
        return viewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        context.coordinator.content = uiViewController
    }

    func makeCoordinator() -> SnapshotViewContainerCoordinator {
        SnapshotViewContainerCoordinator(
            captureTrigger: captureTrigger,
            snapshotHandler: snapshotHandler
        )
    }
}

@MainActor
struct SnapshotViewModifier: ViewModifier {

    var captureTrigger: AnyPublisher<Bool, Never>
    var snapshotHandler: (UIImage) -> Void

    func body(content: Content) -> some View {
        SnapshotViewContainer(
            captureTrigger: captureTrigger,
            snapshotHandler: snapshotHandler
        ) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

extension View {

    @ViewBuilder
    public func snapshot(
        captureTrigger: AnyPublisher<Bool, Never>,
        snapshotHandler: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(
            SnapshotViewModifier(
                captureTrigger: captureTrigger,
                snapshotHandler: snapshotHandler
            )
        )
    }
}
