//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol FlushableBucketItemTransformer {

    associatedtype Input
    associatedtype Output

    func transform(_ input: Input) -> Output?
}
