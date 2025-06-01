//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo

final class DemoStatsAdapter {

    @Injected(\.streamVideo) private var streamVideo

    private var activeCallCancellable: AnyCancellable?
    private var callStatsReportCancellable: AnyCancellable?
    private let disposableBag = DisposableBag()

    @Published private(set) var reports: [CallStatsReport] = []

    init() {
        activeCallCancellable = streamVideo
            .state
            .$activeCall
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in self?.didUpdateActiveCall($0) }
    }

    @MainActor
    private func didUpdateActiveCall(_ call: Call?) {
        reports = []
        callStatsReportCancellable?.cancel()
        callStatsReportCancellable = call?
            .state
            .$statsReport
            .sink { [weak self] in
                if let report = $0 { self?.reports.append(report) }
            }
    }
}

extension DemoStatsAdapter: InjectionKey {
    static var currentValue: DemoStatsAdapter = .init()
}

extension InjectedValues {
    var demoStatsAdapter: DemoStatsAdapter {
        get { Self[DemoStatsAdapter.self] }
        set { Self[DemoStatsAdapter.self] = newValue }
    }
}
