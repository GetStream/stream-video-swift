//
//  VideoView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import SwiftUI

struct VideoView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel: VideoViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: ViewModelFactory.shared.makeVideoViewModel())
    }
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                CameraView(
                    webRTCClient: viewModel.webRTCClient,
                    frame: CGRect(origin: .zero, size: CGSize(width: reader.size.width, height: reader.size.height / 2)),
                    isCurrentUser: true
                )
                .frame(maxHeight: reader.size.height / 2)
                
                CameraView(
                    webRTCClient: viewModel.webRTCClient,
                    frame: CGRect(origin: CGPoint(x: 0, y: reader.size.height / 2), size: CGSize(width: reader.size.width, height: reader.size.height / 2)),
                    isCurrentUser: false
                )
                .frame(maxHeight: reader.size.height / 2)
            }
            .overlay(
                TopRightView {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .foregroundColor(.blue)
                            .frame(width: 36, height: 36)
                    }
                    .offset(y: 40)
                    .padding()
                }
            )
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.all)
    }
    
}

public struct TopRightView<Content: View>: View {
    var content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
        
    public var body: some View {
        HStack {
            Spacer()
            VStack {
                content()
                Spacer()
            }
        }
    }
}
