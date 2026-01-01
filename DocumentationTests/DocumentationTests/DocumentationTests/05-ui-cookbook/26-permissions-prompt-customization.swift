//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        class NoPermissionsPromptViewFactory: ViewFactory {

            func makePermissionsPromptView(call: Call?) -> some View {
                EmptyView()
            }
        }

        let viewFactory = NoPermissionsPromptViewFactory()
        let callView = CallView(
            viewFactory: viewFactory,
            viewModel: viewModel
        )
    }

    container {
        struct CustomPermissionsPromptView: View {
            @Injected(\.urlNavigator) private var urlNavigator

            let call: Call?
            @ObservedObject private var permissions = InjectedValues[\.permissions]
            @State private var isHidden = false

            private var requiresCameraPermission: Bool {
                call?.state.ownCapabilities.contains(.sendVideo) ?? false
            }

            private var requiresMicrophonePermission: Bool {
                call?.state.ownCapabilities.contains(.sendAudio) ?? false
            }

            private var isMissingCameraPermission: Bool {
                requiresCameraPermission && !permissions.hasCameraPermission
            }

            private var isMissingMicrophonePermission: Bool {
                requiresMicrophonePermission && !permissions.hasMicrophonePermission
            }

            var body: some View {
                if (isMissingCameraPermission || isMissingMicrophonePermission) && !isHidden {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)

                        Text(permissionText)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button("Open Settings") {
                                try? urlNavigator.openSettings()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Dismiss") {
                                withAnimation {
                                    isHidden = true
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            private var permissionText: String {
                switch (isMissingCameraPermission, isMissingMicrophonePermission) {
                case (true, true):
                    return "Camera and microphone access required"
                case (true, false):
                    return "Camera access required"
                case (false, true):
                    return "Microphone access required"
                default:
                    return ""
                }
            }
        }

        class CustomPermissionsViewFactory: ViewFactory {

            func makePermissionsPromptView(call: Call?) -> some View {
                CustomPermissionsPromptView(call: call)
            }
        }
    }

    container {
        var permissions = InjectedValues[\.permissions]
        // Check individual permissions
        let hasCameraAccess = permissions.hasCameraPermission
        let hasMicAccess = permissions.hasMicrophonePermission
    }
}
