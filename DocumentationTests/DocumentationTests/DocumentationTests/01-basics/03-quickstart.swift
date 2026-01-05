//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

private func content() {
    container {
        struct VideoDemoSwiftUIApp: View {

            @State var streamVideo: StreamVideoUI?

            init() {
                setupStreamVideo(with: "key1", userCredentials: .demoUser)
            }

            private func setupStreamVideo(
                with apiKey: String,
                userCredentials: UserCredentials
            ) {
                streamVideo = StreamVideoUI(
                    apiKey: apiKey,
                    user: userCredentials.user,
                    token: userCredentials.token,
                    tokenProvider: { result in
                        // Call your networking service to generate a new token here.
                        // When finished, call the result handler with either .success or .failure.
                        result(.success(userCredentials.token))
                    }
                )
            }

            var body: some View {
                NavigationView {
                    ContentView()
                }
            }
        }

        struct ContentView: View {

            @Injected(\.streamVideo) var streamVideo

            @StateObject var callViewModel = CallViewModel()
            @State var callId = ""

            var body: some View {
                VStack {
                    TextField("Insert a call id", text: $callId)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    Button {
                        resignFirstResponder()
                        callViewModel.startCall(
                            callType: "default",
                            callId: callId,
                            members: [ /* Your list of participants goes here. */ ]
                        )
                    } label: {
                        Text("Start a call")
                    }
                }
                .padding()
                .modifier(CallModifier(viewModel: callViewModel))
            }
        }

        struct VideoDemoSwiftUIApp2: View {

            @State var streamVideo: StreamVideoUI?

            init() {
                setupStreamVideo(with: "key1", userCredentials: .demoUser)
            }

            private func setupStreamVideo(
                with apiKey: String,
                userCredentials: UserCredentials
            ) {
                let images = Images()
                images.hangup = Image(systemName: "phone.down")
                let appearance = Appearance(images: images)
                streamVideo = StreamVideoUI(
                    apiKey: apiKey,
                    user: userCredentials.user,
                    token: userCredentials.token,
                    tokenProvider: { result in
                        // Call your networking service to generate a new token here.
                        // When finished, call the result handler with either .success or .failure.
                        result(.success(userCredentials.token))
                    },
                    appearance: appearance
                )
            }

            var body: some View {
                NavigationView {
                    ContentView()
                }
            }
        }

        class CustomViewFactory: ViewFactory {

            func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
                // Here you can also provide your own custom view.
                // In this example, we are re-using the standard one, while also adding an overlay.
                let view = DefaultViewFactory.shared.makeOutgoingCallView(viewModel: viewModel)
                return view.overlay(
                    Text("Custom text overlay")
                )
            }
        }

        struct ContentViewWithCustomViewFactory: View {

            @StateObject var callViewModel = CallViewModel()
            @State var callId = ""

            var body: some View {
                VStack {
                    TextField("Insert a call id", text: $callId)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    Button {
                        resignFirstResponder()
                        callViewModel.startCall(
                            callType: "default",
                            callId: callId,
                            members: [ /* Your list of participants goes here. */ ]
                        )
                    } label: {
                        Text("Start a call")
                    }
                }
                .padding()
                .modifier(CallModifier(viewFactory: CustomViewFactory(), viewModel: callViewModel))
            }
        }
    }
}
