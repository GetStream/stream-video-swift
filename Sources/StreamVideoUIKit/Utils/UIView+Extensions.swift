//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    // MARK: - `embed` family of helpers

    public func embed(_ subview: UIView, insets: NSDirectionalEdgeInsets = .zero) {
        addSubview(subview)

        NSLayoutConstraint.activate([
            subview.leadingAnchor.pinItem(equalTo: leadingAnchor, constant: insets.leading),
            subview.trailingAnchor.pinItem(equalTo: trailingAnchor, constant: -insets.trailing),
            subview.topAnchor.pinItem(equalTo: topAnchor, constant: insets.top),
            subview.bottomAnchor.pinItem(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    public func pinItem(anchors: [LayoutAnchorName] = [.top, .leading, .bottom, .trailing], to view: UIView) {
        anchors
            .map { $0.makeConstraint(fromView: self, toView: view) }
            .forEach { $0.isActive = true }
    }
    
    public func pinItem(anchors: [LayoutAnchorName] = [.top, .leading, .bottom, .trailing], to layoutGuide: UILayoutGuide) {
        anchors
            .compactMap { $0.makeConstraint(fromView: self, toLayoutGuide: layoutGuide) }
            .forEach { $0.isActive = true }
    }
    
    public func pinItem(anchors: [LayoutAnchorName] = [.width, .height], to constant: CGFloat) {
        anchors
            .compactMap { $0.makeConstraint(fromView: self, constant: constant) }
            .forEach { $0.isActive = true }
    }
    
    public var withoutAutoresizingMaskConstraints: Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    func withAccessibilityIdentifier(identifier: String) -> Self {
        accessibilityIdentifier = identifier
        return self
    }

    var isVisible: Bool {
        get { !isHidden }
        set { isHidden = !newValue }
    }
    
    func setAnimatedly(hidden: Bool) {
        Animate({
            self.alpha = hidden ? 0.0 : 1.0
            self.isHidden = hidden
        }) { _ in
            self.isHidden = hidden
        }
    }
    
    /// Returns `UIView` that is flexible along defined `axis`.
    static func spacer(axis: NSLayoutConstraint.Axis) -> UIView {
        UIView().flexible(axis: axis)
    }
}

extension UIView {
    func flexible(axis: NSLayoutConstraint.Axis) -> Self {
        setContentHuggingPriority(.lowest, for: axis)
        return self
    }
}

extension NSLayoutConstraint {
    func priority(_ p: UILayoutPriority) -> Self {
        priority = p
        return self
    }

    func priority(_ p: Float) -> Self {
        priority = UILayoutPriority(p)
        return self
    }
}

extension UILayoutPriority {
    static let lowest = UILayoutPriority(defaultLow.rawValue / 2.0)
}

extension NSLayoutConstraint {
    func setTemporaryConstant(_ value: CGFloat) {
        guard originalConstant == nil else { return }
        originalConstant = constant
        constant = value
    }

    func resetTemporaryConstant() {
        if let original = originalConstant {
            constant = original
            originalConstant = nil
        }
    }

    static var originalConstantKey: UInt8 = 0

    private var originalConstant: CGFloat? {
        get { objc_getAssociatedObject(self, &Self.originalConstantKey) as? CGFloat }
        set { objc_setAssociatedObject(self, &Self.originalConstantKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

@MainActor
public enum LayoutAnchorName {
    case bottom
    case centerX
    case centerY
    case firstBaseline
    case height
    case lastBaseline
    case leading
    case left
    case right
    case top
    case trailing
    case width
    
    func makeConstraint(fromView: UIView, toView: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        switch self {
        case .bottom:
            return fromView.bottomAnchor.pinItem(equalTo: toView.bottomAnchor, constant: constant)
        case .centerX:
            return fromView.centerXAnchor.pinItem(equalTo: toView.centerXAnchor, constant: constant)
        case .centerY:
            return fromView.centerYAnchor.pinItem(equalTo: toView.centerYAnchor, constant: constant)
        case .firstBaseline:
            return fromView.firstBaselineAnchor.pinItem(equalTo: toView.firstBaselineAnchor, constant: constant)
        case .height:
            return fromView.heightAnchor.pinItem(equalTo: toView.heightAnchor, constant: constant)
        case .lastBaseline:
            return fromView.lastBaselineAnchor.pinItem(equalTo: toView.lastBaselineAnchor, constant: constant)
        case .leading:
            return fromView.leadingAnchor.pinItem(equalTo: toView.leadingAnchor, constant: constant)
        case .left:
            return fromView.leftAnchor.pinItem(equalTo: toView.leftAnchor, constant: constant)
        case .right:
            return fromView.rightAnchor.pinItem(equalTo: toView.rightAnchor, constant: constant)
        case .top:
            return fromView.topAnchor.pinItem(equalTo: toView.topAnchor, constant: constant)
        case .trailing:
            return fromView.trailingAnchor.pinItem(equalTo: toView.trailingAnchor, constant: constant)
        case .width:
            return fromView.widthAnchor.pinItem(equalTo: toView.widthAnchor, constant: constant)
        }
    }
    
    func makeConstraint(fromView: UIView, toLayoutGuide: UILayoutGuide, constant: CGFloat = 0) -> NSLayoutConstraint? {
        switch self {
        case .bottom:
            return fromView.bottomAnchor.pinItem(equalTo: toLayoutGuide.bottomAnchor, constant: constant)
        case .centerX:
            return fromView.centerXAnchor.pinItem(equalTo: toLayoutGuide.centerXAnchor, constant: constant)
        case .centerY:
            return fromView.centerYAnchor.pinItem(equalTo: toLayoutGuide.centerYAnchor, constant: constant)
        case .height:
            return fromView.heightAnchor.pinItem(equalTo: toLayoutGuide.heightAnchor, constant: constant)
        case .leading:
            return fromView.leadingAnchor.pinItem(equalTo: toLayoutGuide.leadingAnchor, constant: constant)
        case .left:
            return fromView.leftAnchor.pinItem(equalTo: toLayoutGuide.leftAnchor, constant: constant)
        case .right:
            return fromView.rightAnchor.pinItem(equalTo: toLayoutGuide.rightAnchor, constant: constant)
        case .top:
            return fromView.topAnchor.pinItem(equalTo: toLayoutGuide.topAnchor, constant: constant)
        case .trailing:
            return fromView.trailingAnchor.pinItem(equalTo: toLayoutGuide.trailingAnchor, constant: constant)
        case .width:
            return fromView.widthAnchor.pinItem(equalTo: toLayoutGuide.widthAnchor, constant: constant)
        case .firstBaseline, .lastBaseline:
            // TODO: Log warning? Error?
            return nil
        }
    }
    
    func makeConstraint(fromView: UIView, constant: CGFloat) -> NSLayoutConstraint? {
        switch self {
        case .height:
            return fromView.heightAnchor.pinItem(equalToConstant: constant)
        case .width:
            return fromView.widthAnchor.pinItem(equalToConstant: constant)
        default:
            // TODO: Log warning? Error?
            return nil
        }
    }
}

extension UIView {
    /// According to this property, you can differ whether the current language is `rightToLeft`
    /// and setup actions according to it.
    var currentLanguageIsRightToLeftDirection: Bool {
        traitCollection.layoutDirection == .rightToLeft
    }
}
