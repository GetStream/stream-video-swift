//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

/// A view that can be used as the sourceView for picture-in-picture. This is quite useful as PiP can become
/// very weird if the sourceView isn't in the ViewHierarchy or doesn't have an appropriate size.
struct StreamPictureInPictureView: UIViewRepresentable {

    @Injected(\.utils) private var utils

    var isActive: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        if #available(iOS 15.0, *), isActive {
            // Once the view has been created/updated make sure to assign it to
            // the `StreamPictureInPictureAdapter` in order to allow usage for
            // picture-in-picture.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                utils.pictureInPictureAdapter.sourceView = view
            }
        } else {
            utils.pictureInPictureAdapter.sourceView = nil
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if #available(iOS 15.0, *), isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Once the view has been created/updated make sure to assign it to
                // the `StreamPictureInPictureAdapter` in order to allow usage for
                // picture-in-picture.
                utils.pictureInPictureAdapter.sourceView = uiView
            }
        } else {
            utils.pictureInPictureAdapter.sourceView = nil
        }
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
        self.modifier(PictureInPictureModifier(isActive: isActive))
    }
}
