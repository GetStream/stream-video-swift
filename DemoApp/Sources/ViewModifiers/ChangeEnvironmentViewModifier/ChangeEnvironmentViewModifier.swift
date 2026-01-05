//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct ChangeEnvironmentModifier: ViewModifier {

    @Binding var showChangeEnvironmentPrompt: Bool
    @Binding var changeEnvironmentPromptForURL: URL?

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $showChangeEnvironmentPrompt) {
                if let url = changeEnvironmentPromptForURL {
                    return Alert(
                        title: Text("Change environment"),
                        message: Text(
                            "In order to access the call you scanned, we will need to change the environment you are logged in. Would you like to proceed?"
                        ),
                        primaryButton: .default(Text("OK")) {
                            Router.shared.handle(url: url)
                            showChangeEnvironmentPrompt = false
                            changeEnvironmentPromptForURL = nil
                        },
                        secondaryButton: .cancel {
                            showChangeEnvironmentPrompt = false
                            changeEnvironmentPromptForURL = nil
                        }
                    )
                } else {
                    return Alert(
                        title: Text("Invalid URL"),
                        message: Text("The URL contained in the QR you scanned was invalid. Please try again."),
                        dismissButton: .cancel {
                            showChangeEnvironmentPrompt = false
                            changeEnvironmentPromptForURL = nil
                        }
                    )
                }
            }
    }
}

extension View {

    @ViewBuilder
    func changeEnvironmentIfRequired(
        showPrompt: Binding<Bool>,
        environmentURL: Binding<URL?>
    ) -> some View {
        modifier(
            ChangeEnvironmentModifier(
                showChangeEnvironmentPrompt: showPrompt,
                changeEnvironmentPromptForURL: environmentURL
            )
        )
    }
}
