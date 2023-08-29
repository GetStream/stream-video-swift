//
//  AppCallModifier.swift
//  StreamVideoCallApp
//
//  Created by Ilias Pavlidakis on 19/7/23.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoCallModifier<Factory: ViewFactory>: ViewModifier {

    var viewFactory: Factory
    var viewModel: CallViewModel
    var chatViewModel: StreamChatVideoViewModel

    init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        chatViewModel: StreamChatVideoViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.chatViewModel = chatViewModel
    }

    func body(content: Content) -> some View {
        VideoViewOverlay(
            rootView: content,
            viewFactory: viewFactory,
            viewModel: viewModel
        )
        .environment(\.chatVideoViewModel, chatViewModel)
    }
}

struct ChatVideoViewModel: EnvironmentKey {
    static var defaultValue: StreamChatVideoViewModel?
}

extension EnvironmentValues {
    var chatVideoViewModel: StreamChatVideoViewModel? {
        get { self[ChatVideoViewModel.self] }
        set { self[ChatVideoViewModel.self] = newValue }
    }
}
