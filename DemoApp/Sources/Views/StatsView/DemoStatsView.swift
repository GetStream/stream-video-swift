//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Charts
import Combine
import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoStatsView: View {

    @Injected(\.fonts) private var fonts
    @Injected(\.images) private var images

    @ObservedObject var viewModel: CallViewModel
    var presentationBinding: Binding<Bool>
    var bytesFormatter = ByteCountFormatter()

    var body: some View {
        List {
            if #available(iOS 16.0, *) {
                DemoStatsSection(
                    viewModel: viewModel,
                    iconName: "timer",
                    title: "Call Latency",
                    description: "Very high latency values may reduce call quality, cause lag, and make the call less enjoyable."
                ) {
                    DemoLatencyChartView(viewModel)
                }
                .withoutListSeparator()
            }

            DemoStatsSection(
                viewModel: viewModel,
                iconName: "chart.bar.xaxis",
                title: "Call Performance",
                description: "Very high latency values may reduce call quality, cause lag, and make the call less enjoyable."
            ) {
                VStack(spacing: 16) {
                    row {
                        DemoStatView(
                            viewModel,
                            title: "REGION",
                            value: "none",
                            valueTransformer: { $0?.datacenter.stringValue ?? "" }
                        )
                    } _: {
                        DemoStatView(
                            viewModel,
                            title: "LATENCY",
                            value: 0.0,
                            valueTransformer: { $0?.publisherStats.averageRoundTripTimeInMs ?? 0 },
                            presentationTransformer: { newValue, _ in "\(Int(newValue)) ms" },
                            valueQualityTransformer: { $0 < 100 ? .good : $0 < 150 ? .ok : .bad }
                        )
                    }

                    row {
                        DemoStatView(
                            viewModel,
                            title: "RECEIVE JITTER",
                            value: 0.0,
                            valueTransformer: {
                                $0?.subscriberStats.averageJitterInMs ?? 0
                            },
                            presentationTransformer: { newValue, _ in "\(Int(newValue)) ms" },
                            valueQualityTransformer: { $0 < 100 ? .good : $0 < 150 ? .ok : .bad }
                        )
                    } _: {
                        DemoStatView(
                            viewModel,
                            title: "PUBLISH JITTER",
                            value: 0.0,
                            valueTransformer: { $0?.publisherStats.averageJitterInMs ?? 0 },
                            presentationTransformer: { newValue, _ in "\(Int(newValue)) ms" },
                            valueQualityTransformer: { $0 < 100 ? .good : $0 < 150 ? .ok : .bad }
                        )
                    }

                    row {
                        DemoStatView(
                            viewModel,
                            title: "PUBLISH RESOLUTION",
                            value: "none",
                            valueTransformer: { resolutionFormatter(from: $0?.publisherStats) }
                        )
                    } _: {
                        DemoStatView(
                            viewModel,
                            title: "PUBLISH QUALITY DROP REASON",
                            value: "none",
                            valueTransformer: { qualityLimitationReasonsFormatter(from: $0?.publisherStats) }
                        )
                    }

                    row {
                        DemoStatView(
                            viewModel,
                            title: "RECEIVING RESOLUTION",
                            value: "none",
                            valueTransformer: { resolutionFormatter(from: $0?.subscriberStats) }
                        )
                    } _: {
                        DemoStatView(
                            viewModel,
                            title: "RECEIVE QUALITY DROP REASON",
                            value: "none",
                            valueTransformer: { qualityLimitationReasonsFormatter(from: $0?.subscriberStats) }
                        )
                    }

                    row {
                        DemoStatView(
                            viewModel,
                            title: "PUBLISH BITRATE",
                            value: 0,
                            valueTransformer: { $0?.publisherStats.totalBytesSent ?? 0 },
                            presentationTransformer: { newValue, previousValue in
                                bytesFormatter(from: max(newValue - previousValue, 0))
                            }
                        )
                    } _: {
                        DemoStatView(
                            viewModel,
                            title: "RECEIVING BITRATE",
                            value: 0,
                            valueTransformer: { $0?.subscriberStats.totalBytesReceived ?? 0 },
                            presentationTransformer: { newValue, previousValue in
                                bytesFormatter(from: max(newValue - previousValue, 0))
                            }
                        )
                    }
                }
                .padding(.vertical)
            }
            .withoutListSeparator()
        }
        .listStyle(.plain)
        .withModalNavigationBar(title: "Stats") { presentationBinding.wrappedValue = false }
        .withDragIndicator()
    }

    @ViewBuilder
    private func row(
        @ViewBuilder _ lhs: () -> some View,
        @ViewBuilder _ rhs: () -> some View = { EmptyView() }
    ) -> some View {
        HStack(alignment: .top) {
            lhs()
                .frame(maxWidth: .infinity)

            rhs()
                .frame(maxWidth: .infinity)
        }
    }

    private func resolutionFormatter(
        from report: AggregatedStatsReport?
    ) -> String {
        guard let report else {
            return "none"
        }

        let resolution = CGSize(
            width: report.highestFrameWidth,
            height: report.highestFrameHeight
        )
        if
            resolution != .zero,
            report.highestFramesPerSecond > 0
        {
            return "\(Int(resolution.width))x\(Int(resolution.height))@\(report.highestFramesPerSecond)"
        } else {
            return "none"
        }
    }

    private func qualityLimitationReasonsFormatter(
        from report: AggregatedStatsReport?
    ) -> String {
        if
            let qualityLimitationReasons = report?.qualityLimitationReasons,
            !qualityLimitationReasons.isEmpty {
            return qualityLimitationReasons
        } else {
            return "none"
        }
    }

    private func bytesFormatter(
        from bytes: Int?
    ) -> String {
        if let bytes {
            return "\(bytesFormatter.string(fromByteCount: Int64(bytes)))ps"
        } else {
            return "none"
        }
    }
}

extension View {

    @ViewBuilder
    fileprivate func withoutListSeparator() -> some View {
        if #available(iOS 15.0, *) {
            self
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
                .listRowSeparatorTint(.clear)
                .listSectionSeparatorTint(.clear)
        } else {
            listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
        }
    }
}

private struct DemoStatsSection<Content: View>: View {

    @Injected(\.fonts) private var fonts
    @Injected(\.colors) private var colors

    @ObservedObject var viewModel: CallViewModel

    var iconName: String
    var title: String
    var description: String
    var content: () -> Content

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(Image(systemName: iconName))

                    Text(title)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(colors.text)
                .font(fonts.bodyBold)

                Text(description)
                    .foregroundColor(Color(colors.textLowEmphasis))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(fonts.subheadline)
            }

            content()
        }
    }
}

private struct DemoStatView<Value: Comparable>: View {

    private final class DemoStatViewModel: ObservableObject {

        @ObservedObject private var viewModel: CallViewModel
        private var cancellable: AnyCancellable?

        @Published var title: String
        @Published var value: Value
        @Published var previousValue: Value

        init(
            viewModel: CallViewModel,
            title: String = "",
            value: Value,
            valueTransformer: @escaping (CallStatsReport?) -> Value
        ) {
            self.viewModel = viewModel
            self.title = title
            self.value = value
            previousValue = value
            cancellable = viewModel
                .call?
                .state
                .$statsReport
                .receive(on: DispatchQueue.global(qos: .utility))
                .map(valueTransformer)
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] value in
                    guard let self else { return }
                    self.previousValue = self.value
                    self.value = value
                }
        }
    }

    enum DemoStatQuality {
        case unknown
        case bad
        case ok
        case good
    }

    struct DemoStatQualityBadge: View {

        @Injected(\.colors) private var colors
        @Injected(\.fonts) private var fonts

        var quality: DemoStatQuality

        var body: some View {
            switch quality {
            case .unknown:
                EmptyView()
            case .bad:
                view("Bad", with: colors.accentRed)
            case .ok:
                view("Ok", with: Color(red: 255 / 255, green: 214 / 255, blue: 70 / 255))
            case .good:
                view("Good", with: colors.accentGreen)
            }
        }

        @ViewBuilder
        private func view(_ text: String, with color: Color) -> some View {
            Text(text)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .font(fonts.caption1)
                .minimumScaleFactor(0.5)
                .background(color.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @Injected(\.fonts) private var fonts
    @Injected(\.colors) private var colors

    @StateObject private var viewModel: DemoStatViewModel
    private var presentationTransformer: (Value, Value) -> String
    private var valueQualityTransformer: (Value) -> DemoStatQuality

    init(
        _ callViewModel: CallViewModel,
        title: String,
        value: Value,
        valueTransformer: @escaping (CallStatsReport?) -> Value,
        presentationTransformer: @escaping (Value, Value) -> String = { newValue, _ in "\(newValue)" },
        valueQualityTransformer: @escaping (Value) -> DemoStatQuality = { _ in .unknown }
    ) {
        _viewModel = .init(
            wrappedValue: .init(
                viewModel: callViewModel,
                title: title,
                value: value,
                valueTransformer: valueTransformer
            )
        )
        self.presentationTransformer = presentationTransformer
        self.valueQualityTransformer = valueQualityTransformer
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .font(fonts.subheadline)
                .foregroundColor(Color(colors.textLowEmphasis))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            HStack {
                Text(presentationTransformer(viewModel.value, viewModel.previousValue))
                    .font(fonts.bodyBold)
                    .foregroundColor(colors.text)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                DemoStatQualityBadge(quality: valueQualityTransformer(viewModel.value))
            }
        }
        .multilineTextAlignment(.leading)
    }
}

@available(iOS 16.0, *)
private struct DemoLatencyChartView: View {

    private final class DemoLatencyChartViewModel: ObservableObject {

        @ObservedObject private var viewModel: CallViewModel
        private var cancellable: AnyCancellable?
        private let visibleItems = 8

        private var internalValues: [Double] = [] {
            didSet {
                visibleRange = max(0, internalValues.endIndex - visibleItems)...internalValues.endIndex
                values = Array(internalValues.enumerated())
            }
        }

        @Published var values: [(offset: Int, element: Double)] = []
        @Published var visibleRange: ClosedRange<Int> = 0...0

        init(
            viewModel: CallViewModel
        ) {
            self.viewModel = viewModel
            values = []
            cancellable = viewModel
                .call?
                .state
                .$statsReport
                .receive(on: DispatchQueue.global(qos: .utility))
                .compactMap { $0?.publisherStats.averageRoundTripTimeInMs }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.internalValues.append($0) }
        }
    }

    @Injected(\.colors) private var colors

    @StateObject private var viewModel: DemoLatencyChartViewModel

    init(
        _ callViewModel: CallViewModel
    ) {
        _viewModel = .init(wrappedValue: .init(viewModel: callViewModel))
    }

    var body: some View {
        Chart {
            ForEach(viewModel.values, id: \.offset) { value in
                LineMark(
                    x: .value("Index", value.offset),
                    y: .value("Latency", value.element)
                )
                .foregroundStyle(colors.accentGreen)
                .interpolationMethod(.cardinal)

                PointMark(
                    x: .value("Index", value.offset),
                    y: .value("Latency", value.element)
                )
                .foregroundStyle(colors.accentGreen)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .chartXScale(domain: viewModel.visibleRange)
        .chartXAxis(.hidden)
        .padding(.vertical)
        .padding(.horizontal, 4)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
