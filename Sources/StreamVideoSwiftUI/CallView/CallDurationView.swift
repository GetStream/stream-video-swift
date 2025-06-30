//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View {

    @Injected(\.colors) var colors: Colors
    @Injected(\.fonts) var fonts: Fonts
    @Injected(\.images) var images: Images
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    var viewModel: CallViewModel

    @State var duration: TimeInterval
    @State var recordingState: RecordingState

    public init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        duration = viewModel.call?.state.duration ?? 0
        recordingState = viewModel.call?.state.recordingState ?? .noRecording
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
        .onReceive(viewModel.call?.state.$recordingState.removeDuplicates()) { self.recordingState = $0 }
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

struct TimeView: View {

    @Injected(\.fonts) private var fonts: Fonts
    @Injected(\.colors) private var colors: Colors

    var value: NSMutableAttributedString

    init(_ value: String) {
        let attributed = NSMutableAttributedString(string: value)
        self.value = attributed
        self.value.addAttribute(
            .foregroundColor,
            value: colors.callDurationColor.withAlphaComponent(0.6),
            range: .init(location: 0, length: attributed.length - 3)
        )
        self.value.addAttribute(
            .foregroundColor,
            value: colors.callDurationColor,
            range: .init(location: attributed.length - 3, length: 3)
        )
    }

    var body: some View {
        Group {
            if #available(iOS 15.0, *) {
                Text(AttributedString(value))
            } else {
                Text(value.string)
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .font(fonts.bodyBold.monospacedDigit())
        .minimumScaleFactor(0.2)
        .lineLimit(1)
    }
}
