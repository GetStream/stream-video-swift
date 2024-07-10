//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI
import UIKit

/// Publisher to read keyboard changes.
public protocol KeyboardReadable {
    @MainActor var keyboardWillChangePublisher: AnyPublisher<Bool, Never> { get }
    @MainActor var keyboardDidChangePublisher: AnyPublisher<Bool, Never> { get }
}

/// Default implementation.
extension KeyboardReadable {
    @MainActor public var keyboardWillChangePublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
    
    @MainActor public var keyboardDidChangePublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardDidShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardDidHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}

/// View modifier for hiding the keyboard on tap.
public struct HideKeyboardOnTapGesture: ViewModifier {
    var shouldAdd: Bool
    var onTapped: (() -> Void)?
    
    public init(shouldAdd: Bool, onTapped: (() -> Void)? = nil) {
        self.shouldAdd = shouldAdd
        self.onTapped = onTapped
    }
    
    public func body(content: Content) -> some View {
        content
            .gesture(shouldAdd ? TapGesture().onEnded { _ in
                resignFirstResponder()
                if let onTapped = onTapped {
                    onTapped()
                }
            } : nil)
    }
}

/// Resigns first responder and hides the keyboard.
@MainActor public func resignFirstResponder() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}

public let getStreamFirstResponderNotification = "io.getstream.inputView.becomeFirstResponder"

func becomeFirstResponder() {
    NotificationCenter.default.post(
        name: NSNotification.Name(getStreamFirstResponderNotification),
        object: nil
    )
}
