//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

extension DetailedCallingView {

    struct CallSettingsMenuView: View {

        @State var videoOn: Bool
        @State var audioOn: Bool

        var viewModel: CallViewModel

        init(_ viewModel: CallViewModel) {
            self.viewModel = viewModel
            self.videoOn = viewModel.callSettings.videoOn
            self.audioOn = viewModel.callSettings.audioOn
        }

        var body: some View {
            contentView
                .onReceive(viewModel.$callSettings.map(\.audioOn).removeDuplicates().receive(on: DispatchQueue.main)) {
                    audioOn = $0
                }
                .onReceive(viewModel.$callSettings.map(\.videoOn).removeDuplicates().receive(on: DispatchQueue.main)) {
                    videoOn = $0
                }
        }

        @ViewBuilder
        private var contentView: some View {
            Menu {
                subMenuForSetting(isEnabled: videoOn) {
                    Label { Text("Camera") } icon: { Image(systemName: "camera") }
                } enableAction: {
                    viewModel.toggleCameraEnabled()
                } disableAction: {
                    viewModel.toggleCameraEnabled()
                }

                subMenuForSetting(isEnabled: audioOn) {
                    Label { Text("Microphone") } icon: { Image(systemName: "microphone") }
                } enableAction: {
                    viewModel.toggleMicrophoneEnabled()
                } disableAction: {
                    viewModel.toggleMicrophoneEnabled()
                }
            } label: {
                Image(systemName: "gearshape.fill")
            }
        }

        @ViewBuilder
        private func subMenuForSetting(
            isEnabled: Bool,
            @ViewBuilder label: () -> some View,
            enableAction: @escaping () -> Void,
            disableAction: @escaping () -> Void
        ) -> some View {
            Menu {
                Button {
                    if !isEnabled { enableAction() }
                } label: {
                    Label { Text("Enabled") } icon: { if isEnabled { Image(systemName: "checkmark") } }
                }

                Button {
                    if isEnabled { disableAction() }
                } label: {
                    Label { Text("Disabled") } icon: { if !isEnabled { Image(systemName: "checkmark") } }
                }

            } label: { label() }
        }
    }
}
