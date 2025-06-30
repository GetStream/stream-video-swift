//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallTopView: View {

    var viewModel: CallViewModel

    @State var isLivestream: Bool
    var isLivestreamPublisher: AnyPublisher<Bool, Never>?

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel

        isLivestream = (viewModel.call?.callType == .livestream)
        isLivestreamPublisher = viewModel
            .$call
            .map { $0?.callType == .livestream }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var body: some View {
        contentView
            .onReceive(isLivestreamPublisher) { isLivestream = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        if isLivestream {
            DemoLivestreamTopView(viewModel: viewModel)
        } else {
            DefaultViewFactory
                .shared
                .makeCallTopView(viewModel: viewModel)
        }
    }
}

struct SharingIndicator: View {

    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool

    init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _sharingPopupDismissed = sharingPopupDismissed
    }

    var body: some View {
        HStack {
            Text("You are sharing your screen")
                .font(.headline)
            Divider()
            Button {
                viewModel.stopScreensharing()
            } label: {
                Text("Stop sharing")
                    .font(.headline)
            }
            Button {
                sharingPopupDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }
            .padding(.leading, 4)
        }
        .padding(.all, 8)
        .modifier(ShadowViewModifier())
    }
}

/// Modifier for adding shadow and corner radius to a view.
private struct ShadowViewModifier: ViewModifier {

    var cornerRadius: CGFloat = 16
    var borderColor: Color = Color.gray

    func body(content: Content) -> some View {
        content
            .background(Color(UIColor.systemBackground))
            .cornerRadius(cornerRadius)
            .modifier(ShadowModifier())
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        borderColor,
                        lineWidth: 0.5
                    )
            )
    }
}

/// Modifier for adding shadow to a view.
private struct ShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}
