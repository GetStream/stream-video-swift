//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View {

    var showRingingDuration: Bool

    @ObservedObject private var viewModel: CallViewModel

    public init(_ viewModel: CallViewModel, showRingingDuration: Bool = true) {
        self.viewModel = viewModel
        self.showRingingDuration = showRingingDuration
    }

    public var body: some View {
        contentView
    }

    // MARK: - Private Helpers

    private var accessibilityIdentifier: String {
        viewModel.recordingState == .recording
            ? "recordingView"
            : "callDurationView"
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.callingState {
        case .outgoing where showRingingDuration:
            RingingCallDurationView(Date())
                .accessibility(identifier: accessibilityIdentifier)
        case .inCall:
            InCallDurationView(viewModel)
                .accessibility(identifier: accessibilityIdentifier)
        default:
            EmptyView()
        }
    }
}

private struct InCallDurationView: View {
    @Injected(\.colors) private var colors: Colors
    @Injected(\.images) private var images: Images

    var viewModel: CallViewModel
    @State var duration: TimeInterval

    init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        self._duration = .init(initialValue: viewModel.call?.state.duration ?? 0)
    }

    var body: some View {
        DurationView(duration: duration) {
            if viewModel.recordingState == .recording {
                images.recordIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(colors.inactiveCallControl)
            }
        }
        .onReceive(viewModel.call?.state.$duration) { self.duration = $0 }
    }
}

private struct RingingCallDurationView: View {
    var startedRingingAt: Date
    @State var duration: TimeInterval

    init(_ startRingingAt: Date) {
        self.startedRingingAt = startRingingAt
        self._duration = .init(initialValue: Date().timeIntervalSince(startRingingAt))
    }

    var body: some View {
        DurationView(duration: duration) { EmptyView() }
            .onReceive(DefaultTimer.publish(every: 1).receive(on: DispatchQueue.main)) { _ in duration += 1 }
    }
}

private struct DurationView<IconView: View>: View {

    @Injected(\.colors) private var colors: Colors
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    var duration: TimeInterval
    var iconView: IconView

    init(duration: TimeInterval, @ViewBuilder iconView: () -> IconView) {
        self.duration = duration
        self.iconView = iconView()
    }

    var body: some View {
        if duration > 0, let formattedDuration = formatter.format(duration) {
            HStack(spacing: 4) {
                iconView

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
}

private struct TimeView: View {

    @Injected(\.fonts) private var fonts: Fonts
    @Injected(\.colors) private var colors: Colors

    var value: NSMutableAttributedString

    fileprivate init(_ value: String) {
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

    fileprivate var body: some View {
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
