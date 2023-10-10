//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import XCTest

extension CALayer {
    static func swizzleShadow() {
        swizzle(original: #selector(getter: shadowOpacity), modified: #selector(_swizzled_shadowOpacity))
        swizzle(original: #selector(getter: shadowRadius), modified: #selector(_swizzled_shadowRadius))
        swizzle(original: #selector(getter: shadowColor), modified: #selector(_swizzled_shadowColor))
        swizzle(original: #selector(getter: shadowOffset), modified: #selector(_swizzled_shadowOffset))
        swizzle(original: #selector(getter: shadowPath), modified: #selector(_swizzled_shadowPath))
    }

    static func revertSwizzleShadow() {
        swizzle(original: #selector(_swizzled_shadowOpacity), modified: #selector(getter: shadowOpacity))
        swizzle(original: #selector(_swizzled_shadowRadius), modified: #selector(getter: shadowRadius))
        swizzle(original: #selector(_swizzled_shadowColor), modified: #selector(getter: shadowColor))
        swizzle(original: #selector(_swizzled_shadowOffset), modified: #selector(getter: shadowOffset))
        swizzle(original: #selector(_swizzled_shadowPath), modified: #selector(getter: shadowPath))
    }

    private static func swizzle(original: Selector, modified: Selector) {
        let originalMethod = class_getInstanceMethod(self, original)!
        let swizzledMethod = class_getInstanceMethod(self, modified)!
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc func _swizzled_shadowOpacity() -> Float { .zero }
    @objc func _swizzled_shadowRadius() -> CGFloat { .zero }
    @objc func _swizzled_shadowColor() -> CGColor? { nil }
    @objc func _swizzled_shadowOffset() -> CGSize { .zero }
    @objc func _swizzled_shadowPath() -> CGPath? { nil }
}
