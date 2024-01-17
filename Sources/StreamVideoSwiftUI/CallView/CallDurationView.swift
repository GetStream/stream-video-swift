//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

@available(iOS 14.0, *)
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
        self.duration = viewModel.call?.state.duration ?? 0
    }

    public var body: some View {
        Group {
            if duration > 0, let formattedDuration = formatter.format(duration) {
                HStack(spacing: 4) {
                    iconView
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12)
                    .foregroundColor(
                        viewModel.recordingState == .recording
                        ? colors.accentRed
                        : colors.onlineIndicatorColor
                    )

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
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK - Private Helpers

    private var iconView: Image {
        viewModel.recordingState == .recording
            ? images.recordIcon
            : images.secureCallIcon
    }

    private var accessibilityLabel: String {
        var result = "Call duration: \(duration) seconds."
        if viewModel.recordingState == .recording {
            result += "Recording in progress."
        }

        return result
    }
}

fileprivate struct TimeView: View {

    @Injected(\.fonts) private var fonts: Fonts

    var value: NSMutableAttributedString

    fileprivate init(_ value: String) {
        let attributed = NSMutableAttributedString(string: value)
        self.value = attributed
        self.value.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.6), range: .init(location: 0, length: attributed.length - 3))
        self.value.addAttribute(.foregroundColor, value: UIColor.white, range: .init(location: attributed.length - 3, length: 3))
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