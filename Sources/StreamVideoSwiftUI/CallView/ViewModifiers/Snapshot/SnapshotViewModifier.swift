//
//  SnapshotViewModifier.swift
//  StreamVideoSwiftUI
//
//  Created by Ilias Pavlidakis on 2/2/24.
//

import Foundation
import SwiftUI
import Combine

struct SnapshotViewContainer<Content: View>: UIViewControllerRepresentable {

    typealias UIViewControllerType = UIViewController

    @MainActor
    final class SnapshotViewContainerCoordinator {
        let viewModel: CallViewModel
        private var cancellable: AnyCancellable?

        weak var content: UIViewControllerType?

        init(viewModel: CallViewModel) {
            self.viewModel = viewModel
            cancellable = viewModel
                .$captureSnapshot
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

            viewModel.didCaptureSnapshot(content.view.snapshot())
        }
    }

    let viewModel: CallViewModel
    let contentProvider: () -> Content

    init(
        viewModel: CallViewModel,
        @ViewBuilder contentProvider: @escaping () -> Content
    ) {
        self.viewModel = viewModel
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
        SnapshotViewContainerCoordinator(viewModel: viewModel)
    }
}

@MainActor
struct SnapshotViewModifier: ViewModifier {

    var viewModel: CallViewModel

    func body(content: Content) -> some View {
        SnapshotViewContainer(viewModel: viewModel) {
            content
        }
    }
}

extension View {

    @ViewBuilder
    public func snapshot(
        viewModel: CallViewModel
    ) -> some View {
        modifier(SnapshotViewModifier(viewModel: viewModel))
    }
}
