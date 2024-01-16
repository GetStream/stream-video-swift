//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

/// A view that can be used as the sourceView for Picture In Picture. This is quite useful as PiP can become
/// very weird if the sourceView isn't in the ViewHierarchy or doesn't have an appropriate size.
struct StreamPictureInPictureView: UIViewRepresentable {

    @Injected(\.utils) private var utils

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            // Once the view has been created/updated make sure to assign it to
            // the `StreamPictureInPictureAdapter` in order to allow usage for
            // Picture in Picture.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                utils.pictureInPictureAdapter.sourceView = view
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if #available(iOS 15.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Once the view has been created/updated make sure to assign it to
                // the `StreamPictureInPictureAdapter` in order to allow usage for
                // Picture in Picture.
                utils.pictureInPictureAdapter.sourceView = uiView
            }
        }
    }
}

/// A modifier that makes the view that's being applied the anchorView for Picture in Picture.
/// - Note:The View itself won't be used as sourceView.
struct PictureInPictureModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(StreamPictureInPictureView())
    }
}

extension View {

    /// Make the view that's being applied the anchorView for Picture in Picture.
    /// - Note:The View itself won't be used as sourceView.
    @ViewBuilder
    public func enablePictureInPicture() -> some View {
        self.modifier(PictureInPictureModifier())
    }
}
