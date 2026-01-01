//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, let report = $0 else { return }

                reports.append(report)

                if reports.endIndex > 20 {
                    _ = reports.dropFirst()
                }
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
