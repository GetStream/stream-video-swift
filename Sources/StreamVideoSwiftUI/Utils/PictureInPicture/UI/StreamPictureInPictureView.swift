//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view that can be used as the sourceView for picture-in-picture. This is quite useful as PiP can become
/// very weird if the sourceView isn't in the ViewHierarchy or doesn't have an appropriate size.
struct StreamPictureInPictureView: UIViewRepresentable {
    private var isActive: Bool

    init(isActive: Bool) {
        self.isActive = isActive
    }

    func makeUIView(context: Context) -> UIView { context.coordinator.setUpIfRequired() }

    func updateUIView(_ uiView: UIView, context: Context) { /* No-op */ }

    func makeCoordinator() -> Coordinator { Coordinator(isActive: isActive) }

    final class Coordinator {

        @Injected(\.pictureInPictureAdapter) private var pictureInPictureAdapter

        private var view: UIView?
        private let isActive: Bool
        private var cancellable: AnyCancellable?

        init(isActive: Bool) {
            self.isActive = isActive
        }

        @MainActor
        func setUpIfRequired() -> UIView {
            if let view {
                return view
            } else {
                let view = WindowObservingView()
                view.backgroundColor = .clear
                self.view = view

                cancellable = view
                    .windowPublisher
                    .receive(on: DispatchQueue.main)
                    .filter { $0 != nil }
                    .sink { [weak self, weak view] _ in self?.pictureInPictureAdapter.sourceView = view }

                return view
            }
        }
    }
}

final class WindowObservingView: UIView {
    private let _windowSubject: CurrentValueSubject<UIWindow?, Never> = .init(nil)
    var windowPublisher: AnyPublisher<UIWindow?, Never> { _windowSubject.eraseToAnyPublisher() }

    override public func willMove(toWindow newWindow: UIWindow?) {
        _windowSubject.send(newWindow)
        super.willMove(toWindow: newWindow)
    }
}

/// A modifier that makes the view that's being applied the anchorView for picture-in-picture.
/// - Note:The View itself won't be used as sourceView.
struct PictureInPictureModifier: ViewModifier {

    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .background(StreamPictureInPictureView(isActive: isActive))
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
