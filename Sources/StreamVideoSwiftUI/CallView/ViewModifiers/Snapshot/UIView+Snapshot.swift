//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit

extension UIView {

    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { [weak self] _ in
            guard let self else { return }
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
#endif
