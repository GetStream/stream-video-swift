//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view that can be used as the sourceView for picture-in-picture. This is quite useful as PiP can become
/// very weird if the sourceView isn't in the ViewHierarchy or doesn't have an appropriate size.
struct PictureInPictureSourceView: UIViewRepresentable {

    var isActive: Bool

    static func dismantleUIView(
        _ uiView: UIView,
        coordinator: Coordinator
    ) {
        coordinator.dismantle()
    }

    func makeUIView(context: Context) -> UIView {
        context.coordinator.view.backgroundColor = .clear
        // Apply the initial state here so already-active PiP hosts start
        // observing window changes as soon as the view is created.
        context.coordinator.update(isActive: isActive)
        return context.coordinator.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.update(isActive: isActive)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Private Helpers

    @MainActor
    final class Coordinator {
        @Injected(\.pictureInPictureAdapter) private var pictureInPictureAdapter

        let view: WindowObservingView = .init()
        private var isActive = false
        private var cancellable: AnyCancellable?

        func dismantle() {
            isActive = false
            cancellable?.cancel()
            cancellable = nil
            publishUpdate(false)
        }

        func update(isActive: Bool) {
            guard self.isActive != isActive else { return }

            if isActive {
                cancellable?.cancel()
                cancellable = view
                    .publisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.publishUpdate($0) }
            } else {
                // Clear the adapter immediately when PiP is turned off so it
                // does not retain a stale source view reference.
                dismantle()
            }

            self.isActive = isActive
        }

        private func publishUpdate(_ hasWindow: Bool) {
            pictureInPictureAdapter
                .store?
                .dispatch(.setSourceView(hasWindow ? view : nil))
        }
    }

    final class WindowObservingView: UIView {
        private let windowSubject: CurrentValueSubject<Bool, Never> = .init(false)
        var publisher: AnyPublisher<Bool, Never> { windowSubject.eraseToAnyPublisher() }

        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            windowSubject.send(newWindow != nil)
        }
    }
}

/// A modifier that makes the view that's being applied the anchorView for picture-in-picture.
/// - Note:The View itself won't be used as sourceView.
struct PictureInPictureModifier: ViewModifier {

    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(PictureInPictureSourceView(isActive: isActive))
    }
}

extension View {

    /// Make the view that's being applied the anchorView for picture-in-picture.
    /// - Parameter isActive: Bool, when true enables picture-in-picture support otherwise
    /// disables it.
    /// - Note:The View itself won't be used as sourceView.
    @ViewBuilder
    public func enablePictureInPicture(_ isActive: Bool) -> some View {
        modifier(PictureInPictureModifier(isActive: isActive))
    }
}
