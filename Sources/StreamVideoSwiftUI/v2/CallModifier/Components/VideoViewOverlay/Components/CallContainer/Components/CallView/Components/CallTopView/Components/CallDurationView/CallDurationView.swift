//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View {

    @Injected(\.colors) private var colors: Colors
    @Injected(\.fonts) private var fonts: Fonts
    @Injected(\.images) private var images: Images
    @Injected(\.timers) private var timers
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    var viewModel: CallViewModel
    @State var recordingState: RecordingState
    @State var duration: TimeInterval

    public init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        duration = viewModel.call?.state.duration ?? 0
        recordingState = viewModel.recordingState
    }

    public var body: some View {
        Group {
            if let formattedDuration = formatter.format(duration) {
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
        .accessibility(identifier: accessibilityIdentifier)
        .onReceive(viewModel.call?.state.$duration) { duration = $0 }
        .onReceive(viewModel.$recordingState) { recordingState = $0 }
    }

    // MARK: - Private Helpers

    private var foregroundColor: Color {
        recordingState == .recording
            ? colors.inactiveCallControl
            : colors.onlineIndicatorColor
    }

    @ViewBuilder
    private var iconView: some View {
        if recordingState == .recording {
            images.recordIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12)
        }
    }

    private var accessibilityIdentifier: String {
        recordingState == .recording
            ? "recordingView"
            : "callDurationView"
    }
}
