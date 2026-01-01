//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A transformer used by `ConsumableBucket` to map source values to
/// consumable elements.
///
/// This protocol allows a bucket to observe one data type while
/// storing another, through a transformation step. Implementors define
/// the transformation logic between `Input` and `Output`.
protocol ConsumableBucketItemTransformer {

    /// The input type received from the upstream publisher.
    associatedtype Input
    /// The output type to be stored in the `ConsumableBucket`.
    associatedtype Output

    /// Transforms an input into a bucket-storable output value.
    ///
    /// - Parameter input: The incoming value to transform.
    /// - Returns: The transformed output.
    func transform(_ input: Input) -> Output
}
