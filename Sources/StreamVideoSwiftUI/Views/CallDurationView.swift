//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View {

    @Injected(\.colors) private var colors: Colors
    @Injected(\.fonts) private var fonts: Fonts
    @Injected(\.images) private var images: Images
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    @State private var duration: TimeInterval
    @ObservedObject private var viewModel: CallViewModel

    @MainActor
    public init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        _duration = .init(initialValue: viewModel.call?.state.duration ?? 0)
    }

    public var body: some View {
        Group {
            if duration > 0, let formattedDuration = formatter.format(duration) {
                HStack(spacing: 4) {
                    iconView
                        .foregroundColor(foregroundColor)

                    TimeView(formattedDuration)
                        .layoutPriority(2)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(colors.participantBackground))
                .clipShape(Capsule())
            } else {
                EmptyView()
            }
        }
        .onReceive(viewModel.call?.state.$duration) { self.duration = $0 }
        .accessibility(identifier: accessibilityIdentifier)
    }

    // MARK: - Private Helpers

    private var foregroundColor: Color {
        viewModel.recordingState == .recording
            ? colors.inactiveCallControl
            : colors.onlineIndicatorColor
    }

    @ViewBuilder
    private var iconView: some View {
        if viewModel.recordingState == .recording {
            images.recordIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12)
        } else {
            EmptyView()
        }
    }

    private var accessibilityIdentifier: String {
        viewModel.recordingState == .recording
            ? "recordingView"
            : "callDurationView"
    }
}
