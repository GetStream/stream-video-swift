//
//  UIView+Snapshot.swift
//  StreamVideoSwiftUI
//
//  Created by Ilias Pavlidakis on 2/2/24.
//

import Foundation
#if canImport(UIKit)
import UIKit

extension UIView {

    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { [weak self] _ in
            guard let self else { return }
            self.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
#endif
