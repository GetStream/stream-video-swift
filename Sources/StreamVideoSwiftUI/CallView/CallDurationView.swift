//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View, @preconcurrency Equatable {

    @Injected(\.colors) private var colors: Colors
    @Injected(\.fonts) private var fonts: Fonts
    @Injected(\.images) private var images: Images
    @Injected(\.timers) private var timers
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    @State var duration: TimeInterval
    var recordingState: RecordingState

    @MainActor
    public init(_ viewModel: CallViewModel) {
        if let startedAt = viewModel.call?.state.startedAt {
            self.init(
                duration: Date().timeIntervalSince(startedAt),
                recordingState: viewModel.recordingState
            )
        } else {
            self.init(
                duration: 0,
                recordingState: viewModel.recordingState
            )
        }
    }

    init(
        duration: TimeInterval,
        recordingState: RecordingState
    ) {
        self.duration = duration
        self.recordingState = recordingState
    }

    public static func == (
        lhs: CallDurationView,
        rhs: CallDurationView
    ) -> Bool {
        lhs.duration == rhs.duration
            && lhs.recordingState == rhs.recordingState
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
        .onReceive(timers.timer(for: 1)) { _ in duration += 1 }
        .accessibility(identifier: accessibilityIdentifier)
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
