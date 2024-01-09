//
//  StreamPictureInPIctureView.swift
//  StreamVideoSwiftUI
//
//  Created by Ilias Pavlidakis on 9/1/24.
//

import Foundation
import SwiftUI

struct StreamPictureInPictureView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                StreamPictureInPictureAdapter.shared.sourceView = view
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if #available(iOS 15.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                StreamPictureInPictureAdapter.shared.sourceView = uiView
            }
        }
    }
}

struct PictureInPictureModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .background(StreamPictureInPictureView())
    }
}

extension View {

    @ViewBuilder
    public func enablePictureInPicture() -> some View {
        self.modifier(PictureInPictureModifier())
    }
}

import UIKit

extension UIApplication {
    class func topViewController(
        controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
