//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamSwiftTestHelpers
import XCTest

extension XCTestCase {

    struct ResultValue<T: Comparable>: CustomStringConvertible {

        var local: T
        var ci: T
        var stringTransformer: (T) -> String

        var description: String {
            "\(stringTransformer(value)) { local:\(stringTransformer(local)), ci:\(stringTransformer(ci)) }"
        }

        var value: T {
            TestRunnerEnvironment.isCI ? ci : local
        }

        init(
            local: T,
            ci: T,
            stringTransformer: @escaping (T) -> String = { "\($0)" }
        ) {
            self.local = local
            self.ci = ci
            self.stringTransformer = stringTransformer
        }

        init(
            _ value: T,
            stringTransformer: @escaping (T) -> String = { "\($0)" }
        ) {
            self.local = value
            self.ci = value
            self.stringTransformer = stringTransformer
        }
    }

    func measure(
        baseline: ResultValue<TimeInterval>,
        allowedRegression: ResultValue<Double> = .init(local: 0.15, ci: 0.25), // Default: local: 15%, ci: 25%
        iterations: Int = 10,
        warmup: Int = 2,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: () -> Void
    ) {
        guard baseline.value > 0 else {
            XCTFail("Baseline must be > 0 for \(name)", file: file, line: line)
            return
        }

        let samples = _measureWallClockMedian(
            iterations: iterations,
            warmup: warmup,
            block: block
        )

        let measured = samples.sorted()[samples.endIndex / 2] // median
        let diff = measured - baseline.value
        let ratio = diff / baseline.value
        if diff > 0, ratio > allowedRegression.value {
            XCTFail(
                """
                Performance regression: \(function) (\(file):\(line))
                 Iterations:\(iterations), WarmUp:\(warmup)
                 Baseline: \(baseline)
                 Measured: \(String(format: "%.4f", measured))s
                  - Samples recorded: \(samples)
                 Regression: \(Int(ratio * 100))%
                """,
                file: file,
                line: line
            )
        } else {
            print(
                """
                Performance measurement: \(function) (\(file):\(line))
                 Iterations:\(iterations), WarmUp:\(warmup)
                 Baseline: \(baseline)
                 Measured: \(String(format: "%.4f", measured))s
                  - Samples recorded: \(samples)
                 Ratio: \(Int(ratio * 100))%
                """
            )
        }
    }

    /// Measures wall-clock time for `iterations` runs and returns the median.
    ///
    /// - Important: This is intended for CI-safe regression checks. Use median to
    ///   reduce noise, and keep `iterations` modest to avoid long test times.
    private func _measureWallClockMedian(
        iterations: Int = 10,
        warmup: Int = 2,
        file: StaticString = #file,
        line: UInt = #line,
        block: () throws -> Void
    ) rethrows -> [TimeInterval] {
        precondition(iterations > 0)

        // Warm-up runs (not measured)
        for _ in 0..<warmup {
            try block()
        }

        var samples: [TimeInterval] = []
        samples.reserveCapacity(iterations)

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            try block()
            let end = CFAbsoluteTimeGetCurrent()
            samples.append(end - start)
        }

        return samples
    }
}
