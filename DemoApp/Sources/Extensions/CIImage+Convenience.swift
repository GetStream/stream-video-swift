//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import CoreImage
import Foundation
import UIKit

extension CIImage {
    convenience init?(resource name: String, ofType type: String) {
        guard
            let path = Bundle.main.path(forResource: name, ofType: type),
            let image = UIImage(contentsOfFile: path) else {
            return nil
        }
        self.init(image: image)
    }
}
#endif
