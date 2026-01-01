//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

private struct DemoAlertWithTextFieldViewModifier<Value: CustomStringConvertible>: ViewModifier {

    var title: String
    var message: String?
    var placeholder: String
    var presentationBinding: Binding<Bool>
    var valueBinding: Binding<Value>
    var transformer: (String) -> Value
    var action: () -> Void

    private var transformedBinding: Binding<String> {
        .init(
            get: { "\(valueBinding.wrappedValue)" },
            set: { valueBinding.wrappedValue = transformer($0) }
        )
    }

    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .alert(title, isPresented: presentationBinding) {
                    TextField(
                        placeholder,
                        text: transformedBinding
                    )
                    .foregroundColor(.gray)
                    Button("OK", action: action)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    if let message {
                        Text(message)
                    }
                }
        } else {
            content
        }
    }
}

extension View {

    @ViewBuilder
    func alertWithTextField<Value: CustomStringConvertible>(
        title: String,
        message: String? = nil,
        placeholder: String,
        presentationBinding: Binding<Bool>,
        valueBinding: Binding<Value>,
        transformer: @escaping (String) -> Value,
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            DemoAlertWithTextFieldViewModifier(
                title: title,
                message: message,
                placeholder: placeholder,
                presentationBinding: presentationBinding,
                valueBinding: valueBinding,
                transformer: transformer,
                action: action
            )
        )
    }
}
