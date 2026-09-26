//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View {

    private let showRingingDuration: Bool

    @ObservedObject private var viewModel: CallViewModel

    /// Creates a duration view for the provided call view model.
    ///
    /// - Parameters:
    ///   - viewModel: The view model that supplies the current calling state and
    ///     in-call duration updates.
    ///   - showRingingDuration: When `true`, the view shows a locally tracked
    ///     timer while the call is still ringing in the outgoing state. Once the
    ///     call is connected, the view always switches to the backend-provided
    ///     call duration.
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
    @Injected(\.videoAppearance) private var videoAppearance

    let viewModel: CallViewModel
    @State private var duration: TimeInterval

    init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        self._duration = .init(initialValue: viewModel.call?.state.duration ?? 0)
    }

    var body: some View {
        DurationView(duration: duration) {
            if viewModel.recordingState == .recording {
                videoAppearance.images.recordIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(Color(colors.accentError))
            }
        }
        .onReceive(viewModel.call?.state.$duration) { self.duration = $0 }
    }
}

private struct RingingCallDurationView: View {
    private let startedRingingAt: Date
    @State private var duration: TimeInterval

    init(_ startRingingAt: Date) {
        self.startedRingingAt = startRingingAt
        self._duration = .init(initialValue: Date().timeIntervalSince(startRingingAt).rounded())
    }

    var body: some View {
        DurationView(duration: duration) { EmptyView() }
            .onReceive(DefaultTimer.publish(every: 1).receive(on: DispatchQueue.main)) { _ in duration += 1 }
    }
}

private struct DurationView<IconView: View>: View {

    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    let duration: TimeInterval
    private let iconView: IconView

    init(duration: TimeInterval, @ViewBuilder iconView: () -> IconView) {
        self.duration = duration
        self.iconView = iconView()
    }

    var body: some View {
        if duration > 0, let formattedDuration = formatter.format(duration) {
            HStack(spacing: layout.spacingXxs) {
                iconView

                TimeView(formattedDuration)
                    .layoutPriority(2)
            }
            .padding(.horizontal, layout.spacingMd)
            .padding(.vertical, layout.spacingXxs)
            .background(Color(colors.backgroundCoreSurfaceDefault))
            .clipShape(Capsule())
        } else {
            EmptyView()
        }
    }
}

private struct TimeView: View {

    var value: NSMutableAttributedString

    fileprivate init(_ value: String) {
        let attributed = NSMutableAttributedString(string: value)
        self.value = attributed
        self.value.addAttribute(
            .foregroundColor,
            value: colors.textTertiary,
            range: .init(location: 0, length: attributed.length - 3)
        )
        self.value.addAttribute(
            .foregroundColor,
            value: colors.textPrimary,
            range: .init(location: attributed.length - 3, length: 3)
        )
    }

    fileprivate var body: some View {
        Group {
            if #available(iOS 15.0, *) {
                Text(AttributedString(value))
            } else {
                Text(value.string)
                    .foregroundColor(Color(colors.textTertiary))
            }
        }
        .font(fonts.bodyBold.monospacedDigit())
        .minimumScaleFactor(0.2)
        .lineLimit(1)
    }
}
