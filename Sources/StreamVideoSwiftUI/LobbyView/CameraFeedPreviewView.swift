//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct CameraFeedPreviewView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors

    var viewFactory: Factory

    @State var videoOn: Bool
    var videoOnPublisher: AnyPublisher<Bool, Never>

    @State var preview: Image?
    var previewPublisher: AnyPublisher<Image?, Never>

    @MainActor
    init(
        viewFactory: Factory,
        viewModel: LobbyViewModel
    ) {
        self.viewFactory = viewFactory

        videoOn = viewModel.videoOn
        videoOnPublisher = viewModel.$videoOn.removeDuplicates().eraseToAnyPublisher()

        preview = viewModel.viewFinderImage
        previewPublisher = viewModel.$viewFinderImage.eraseToAnyPublisher()
    }

    var body: some View {
        contentView
            .onReceive(videoOnPublisher) { videoOn = $0 }
            .onReceive(previewPublisher) { preview = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        GeometryReader { proxy in
            if videoOn, let preview {
                previewView(with: preview, proxy: proxy)
            } else {
                placeholderView
            }
        }
    }

    @ViewBuilder
    func previewView(with image: Image, proxy: GeometryProxy) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .accessibility(identifier: "cameraCheckView")
            .streamAccessibility(value: "1")
            .frame(width: proxy.size.width, height: proxy.size.height)
    }

    @ViewBuilder
    var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(colors.lobbySecondaryBackground)

            viewFactory.makeUserAvatar(
                streamVideo.user,
                with: .init(size: 80) { AnyView(failbackView) }
            )
        }
        .accessibility(identifier: "cameraCheckView")
        .streamAccessibility(value: "0")
    }

    @ViewBuilder
    var failbackView: some View {
        if let firstCharacter = streamVideo.user.name.first {
            Text(String(firstCharacter))
                .fontWeight(.medium)
                .foregroundColor(colors.text)
                .frame(width: 80, height: 80)
                .background(colors.lobbyBackground)
                .clipShape(Circle())
        }
    }
}
