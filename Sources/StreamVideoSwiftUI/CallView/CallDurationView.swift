//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view that presents the call's duration and recording state.
public struct CallDurationView: View {

    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter
    @Injected(\.images) private var images: Images

    @ObservedObject private var viewModel: CallViewModel
    @State private var duration: TimeInterval
    @Environment(\.callDurationViewStyle) private var style: Style

    private let showRingingDuration: Bool

    /// Creates a duration view for the provided call view model.
    ///
    /// Customize the chip with ``EnvironmentValues/callDurationViewStyle``.
    ///
    /// - Parameters:
    ///   - viewModel: The view model that supplies the current calling state and
    ///     in-call duration updates.
    ///   - showRingingDuration: When `true`, the view shows a locally tracked
    ///     timer while the call is still ringing in the outgoing state. Once the
    ///     call is connected, the view always switches to the backend-provided
    ///     call duration.
    public init(
        _ viewModel: CallViewModel,
        showRingingDuration: Bool = true
    ) {
        self.viewModel = viewModel
        self.showRingingDuration = showRingingDuration
        self._duration = .init(initialValue: {
            switch viewModel.callingState {
            case .inCall:
                return viewModel.call?.state.duration ?? 0
            default:
                return 0
            }
        }())
    }

    public var body: some View {
        withPublisher {
            ApplyStyle(style: style, configuration: configuration)
                .equatable()
        }
    }

    // MARK: - Private Helpers

    private var configuration: Configuration {
        Configuration(
            viewModel: viewModel,
            duration: duration,
            formattedDuration: formatter.format(duration) ?? "",
            icon: icon
        )
    }

    private var accessibilityIdentifier: String {
        viewModel.recordingState == .recording
            ? "recordingView"
            : "callDurationView"
    }

    private var icon: Image? {
        switch viewModel.callingState {
        case .inCall where viewModel.recordingState == .recording:
            return images.recordIcon
        default:
            return nil
        }
    }

    @ViewBuilder
    private func withPublisher<Content: View>(_ content: () -> Content) -> some View {
        switch viewModel.callingState {
        case .outgoing where showRingingDuration:
            content()
                .onReceive(DefaultTimer.publish(every: 1).receive(on: DispatchQueue.main)) { _ in duration += 1 }
                .accessibility(identifier: accessibilityIdentifier)
        case .inCall:
            content()
                .onReceive(viewModel.call?.state.$duration) { self.duration = $0 }
                .accessibility(identifier: accessibilityIdentifier)
        default:
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

extension CallDurationView {
    /// Values passed to ``CallDurationView/Style/makeBody(configuration:)``.
    public struct Configuration: Equatable, @unchecked Sendable {
        public var viewModel: CallViewModel
        public var duration: TimeInterval
        public var formattedDuration: String
        public var icon: Image?

        @MainActor
        @ViewBuilder
        public var label: some View { TimeView(formattedDuration) }

        public static func == (
            lhs: CallDurationView.Configuration,
            rhs: CallDurationView.Configuration
        ) -> Bool {
            lhs.viewModel === rhs.viewModel
            && lhs.duration == rhs.duration
            && lhs.formattedDuration == rhs.formattedDuration
            && lhs.icon == rhs.icon
        }
    }

    /// Renders the duration chip.
    ///
    /// Subclass and override ``makeBody(configuration:)``. Return ``AnyView``,
    /// then inject the style with ``EnvironmentValues/callDurationViewStyle``.
    ///
    /// ```swift
    /// final class MyStyle: CallDurationView.Style {
    ///     override func makeBody(
    ///         configuration: CallDurationView.Configuration
    ///     ) -> AnyView {
    ///         AnyView(Text(configuration.formattedDuration))
    ///     }
    /// }
    ///
    /// CallDurationView(viewModel)
    ///     .environment(\.callDurationViewStyle, MyStyle())
    /// ```
    open class Style: StyleProtocol, @unchecked Sendable {
        @Injected(\.colors) private var colors: Colors

        public init() {}

        open func makeBody(configuration: Configuration) -> AnyView {
            if configuration.duration > 0, !configuration.formattedDuration.isEmpty {
                return AnyView(
                    HStack(spacing: 4) {
                        if let icon = configuration.icon {
                            icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 12)
                                .foregroundColor(colors.inactiveCallControl)
                        }

                        configuration
                            .label
                            .layoutPriority(2)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color(colors.participantBackground))
                    .clipShape(Capsule())
                )
            } else {
                return AnyView(EmptyView())
            }
        }
    }
}

extension EnvironmentValues {
    /// Style used by ``CallDurationView``. Defaults to ``CallDurationView/Style``.
    @Entry
    public var callDurationViewStyle: CallDurationView.Style = .init()
}
