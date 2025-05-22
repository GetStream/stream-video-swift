//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

#if canImport(MLCompute)
import MLCompute

let neuralEngineExists = if #available(iOS 15.0, *) {
    MLCDevice.ane() != nil
} else {
    false
}
#else
let neuralEngineExists = false
#endif
