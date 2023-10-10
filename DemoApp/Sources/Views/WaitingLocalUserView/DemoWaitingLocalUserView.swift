//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoWaitingLocalUserView<Factory: DemoAppViewFactory>: View {

    @Injected(\.appearance) var appearance
    @Injected(\.chatViewModel) var chatViewModel

    @ObservedObject var viewModel: CallViewModel

    @State private var isSharePresented = false

    private let viewFactory: Factory

    internal init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            viewFactory
                .makeInnerWaitingLocalUserView(viewModel: viewModel)

            if chatViewModel?.isChatVisible == true {
                VStack {
                    Spacer()
                    VStack {
                        LinkInfoView()

                        Button {
                            let pasteboard = UIPasteboard.general
                            pasteboard.string = callLink
                        } label: {
                            HStack {
                                Text(callLink)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(appearance.colors.text)
                                Spacer()
                                Image(systemName: "doc.on.doc")
                            }
                            .padding(.all, 12)
                            .background(Color(appearance.colors.background))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))
                            .padding(.vertical)
                        }

                        Button {
                            isSharePresented = true
                        } label: {
                            Text("Share")
                                .bold()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .background(appearance.colors.primaryButtonBackground)
                        .cornerRadius(8)
                        .padding(.vertical)
                        .sheet(isPresented: $isSharePresented) {
                            if let url = URL(string: callLink) {
                                ShareActivityView(activityItems: [url])
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    .padding()
                    .background(appearance.colors.callControlsBackground.opacity(0.95))
                    .cornerRadius(16)
                    .frame(height: 200)
                    .padding()
                    .offset(y: -125)
                }
            }
        }
        .chat(viewModel: viewModel, chatViewModel: chatViewModel)
    }

    private var callLink: String {
        AppEnvironment
            .baseURL
            .url
            .appendingPathComponent("video")
            .appendingPathComponent("demos")
            .addQueryParameter("id", value: callId)
            .addQueryParameter("type", value: callType)
            .absoluteString
    }

    private var callType: String {
        viewModel.call?.callType ?? .default
    }

    private var callId: String {
        viewModel.call?.callId ?? ""
    }
}
