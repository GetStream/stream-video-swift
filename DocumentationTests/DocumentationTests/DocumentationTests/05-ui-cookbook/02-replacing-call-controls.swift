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
        class CustomViewFactory: ViewFactory {

            public func makeCallControlsView(viewModel: CallViewModel) -> some View {
                CustomCallControlsView(viewModel: viewModel)
            }
        }
    }

    container {
        struct CustomCallControlsView: View {

            @ObservedObject var viewModel: CallViewModel

            var body: some View {
                HStack(spacing: 32) {
                    VideoIconView(viewModel: viewModel)
                    MicrophoneIconView(viewModel: viewModel)
                    ToggleCameraIconView(viewModel: viewModel)
                    HangUpIconView(viewModel: viewModel)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 85)
            }
        }
    }

    container {
        struct FBCallControlsView: View {

            @ObservedObject var viewModel: CallViewModel

            var body: some View {
                HStack(spacing: 24) {
                    Button {
                        viewModel.toggleCameraEnabled()
                    } label: {
                        Image(systemName: "video.fill")
                    }

                    Spacer()

                    Button {
                        viewModel.toggleMicrophoneEnabled()
                    } label: {
                        Image(systemName: "mic.fill")
                    }

                    Spacer()

                    Button {
                        viewModel.toggleCameraPosition()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                    }

                    Spacer()

                    HangUpIconView(viewModel: viewModel)
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .modifier(BackgroundModifier())
                .padding(.horizontal, 32)
            }

            struct BackgroundModifier: ViewModifier {

                func body(content: Content) -> some View {
                    if #available(iOS 15, *) {
                        content
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 24)
                            )
                    } else {
                        content
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(24)
                    }
                }
            }

            class CustomViewFactory: ViewFactory {

                func makeCallControlsView(viewModel: CallViewModel) -> some View {
                    FBCallControlsView(viewModel: viewModel)
                }
            }
        }
    }
}
