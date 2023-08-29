//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct CustomWaitingLocalUserView: View {
    
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    var viewFactory: DemoAppViewFactory
    
    @State private var isSharePresented = false
    
    var body: some View {
        ZStack {
            WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
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
                            Spacer()
                            Image(systemName: "doc.on.doc")
                        }
                        .foregroundColor(Color(colors.textLowEmphasis))
                        .padding(.all, 12)
                        .background(Color("textFieldBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("textFieldBorder"), lineWidth: 1)
                        )
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
                    .background(colors.primaryButtonBackground)
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
                .background(colors.callControlsBackground.opacity(0.95))
                .cornerRadius(16)
                .frame(height: 200)
                .padding()
                .offset(y: -125)
            }
        }
    }
    
    private var callLink: String {
        AppEnvironment.baseURL.url
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

struct LinkInfoView: View {
    
    @Injected(\.colors) var colors
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(colors.primaryButtonBackground)
                    .frame(width: 36, height: 36)
                    
                Image("logo")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22)
                    .foregroundColor(.white)
                    
            }
            
            Text("Send the URL below to someone to have them join this call:")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
}
