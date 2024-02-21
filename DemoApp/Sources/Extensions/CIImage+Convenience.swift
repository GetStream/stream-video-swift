//
//  CIImage+Convenience.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 22/2/24.
//

#if canImport(UIKit)
import Foundation
import CoreImage
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
