//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
