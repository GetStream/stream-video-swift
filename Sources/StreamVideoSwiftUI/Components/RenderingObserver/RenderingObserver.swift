//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

extension View {
    func debugViewRendering(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> some View {
        RenderingObserver.currentValue.addRendering(file: file, function: function, line: line)
        return self
    }
}

final class RenderingObserver {

    private let queue = UnfairQueue()
    private var items: [String] = []
    private let disposableBag = DisposableBag()

    init() {
        Foundation
            .Timer
            .publish(every: ScreenPropertiesAdapter.currentValue.refreshRate, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in self?.printReport() }
            .store(in: disposableBag)
    }

    func addRendering(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        queue.sync { self.items.append("\(URL(fileURLWithPath: "\(file)").lastPathComponent.split(separator: ".")[0])") }
    }

    private func printReport() {
        let report = queue.sync {
            let value = items
            self.items = []
            return value
        }

        guard !report.isEmpty else {
            return
        }

        let message = "Rendering cycle: \(report)"
        log.debug(message)
    }
}

extension RenderingObserver: InjectionKey {
    nonisolated(unsafe) static var currentValue: RenderingObserver = .init()
}

extension InjectedValues {
    var renderingObserver: RenderingObserver {
        get { Self[RenderingObserver.self] }
        set { Self[RenderingObserver.self] = newValue }
    }
}
