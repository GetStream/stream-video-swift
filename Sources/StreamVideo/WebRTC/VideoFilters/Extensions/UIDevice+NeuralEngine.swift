//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

#if canImport(MLCompute)
import MLCompute
var neuralEngineExists = {
    if #available(iOS 15.0, *) {
        return MLCDevice.ane() != nil
    } else {
        return false
    }
}()
#else
var neuralEngineExists = false
#endif
