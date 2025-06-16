//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView: View {

    private let viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            HStack(spacing: 0) {
                HStack {
                    layoutMenuView
                    toggleCameraView
                    Spacer()
                }
                .frame(maxWidth: .infinity)

                HStack(alignment: .center) {
                    callDurationView
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)

                HStack {
                    Spacer()
                    hangUpIconView
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .overlay(sharingIndicatorView)
        .presentParticipantEventsNotification(viewModel: viewModel)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var layoutMenuView: some View {
        LayoutMenuView(viewModel: viewModel)
    }

    @ViewBuilder
    private var toggleCameraView: some View {
        ToggleCameraIconView(viewModel: viewModel)
    }

    @ViewBuilder
    private var callDurationView: some View {
        CallDurationView(viewModel)
    }

    @ViewBuilder
    private var hangUpIconView: some View {
        HangUpIconView(viewModel: viewModel)
    }

    @ViewBuilder
    private var sharingIndicatorView: some View {
        SharingIndicator(viewModel: viewModel)
    }
}

extension View {
    @ViewBuilder
    public func debugLifecycle(width: CGFloat = 5) -> some View {
        border(
            Color(
                red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1)
            ),
            width: width
        )
    }
}
