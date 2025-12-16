//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func measure(
        baseline: TimeInterval,
        allowedRegression: Double = 0.1, // Default: 10%
        iterations: Int = 10,
        warmup: Int = 2,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        block: () -> Void
    ) {
        guard baseline > 0 else {
            XCTFail("Baseline must be > 0 for \(name)", file: file, line: line)
            return
        }

        let samples = _measureWallClockMedian(
            iterations: iterations,
            warmup: warmup,
            block: block
        )

        let measured = samples.sorted()[samples.endIndex / 2] // median
        let ratio = abs(measured - baseline) / baseline
        if ratio > allowedRegression {
            XCTFail(
                """
                Performance regression: \(function) (\(file):\(line))
                 Iterations:\(iterations), WarmUp:\(warmup)
                 Baseline: \(String(format: "%.4f", baseline))s
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
                Performance regression: \(function) (\(file):\(line))
                 Iterations:\(iterations), WarmUp:\(warmup)
                 Baseline: \(String(format: "%.4f", baseline))s
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
