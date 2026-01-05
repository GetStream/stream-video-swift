//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CallKit
import Combine
import CoreImage
import Foundation
import StreamWebRTC

#if compiler(>=6.0)
extension AnyCancellable: @retroactive @unchecked Sendable {}
extension AVCaptureDevice: @retroactive @unchecked Sendable {}
extension AVCapturePhotoOutput: @retroactive @unchecked Sendable {}
extension AVCaptureVideoDataOutput: @retroactive @unchecked Sendable {}
extension CMSampleBuffer: @retroactive @unchecked Sendable {}
extension CXAnswerCallAction: @retroactive @unchecked Sendable {}
extension CXSetHeldCallAction: @retroactive @unchecked Sendable {}
extension CXSetMutedCallAction: @retroactive @unchecked Sendable {}
extension KeyPath: @retroactive @unchecked Sendable {}
extension RTCIceCandidate: @retroactive @unchecked Sendable {}
extension RTCMediaStreamTrack: @retroactive @unchecked Sendable {}
extension RTCSessionDescription: @retroactive @unchecked Sendable {}
extension RTCStatisticsReport: @retroactive @unchecked Sendable {}
extension WritableKeyPath: @retroactive @unchecked Sendable {}
extension Published.Publisher: @retroactive @unchecked Sendable {}
extension RTCVideoFrame: @retroactive @unchecked Sendable {}
extension AnyPublisher: @retroactive @unchecked Sendable {}
extension Publishers.Filter: @retroactive @unchecked Sendable {}
/// Allows audio buffers to cross concurrency boundaries.
extension AVAudioPCMBuffer: @retroactive @unchecked Sendable {}
#else
extension AnyCancellable: @unchecked Sendable {}
extension AVCaptureDevice: @unchecked Sendable {}
extension AVCapturePhotoOutput: @unchecked Sendable {}
extension AVCaptureVideoDataOutput: @unchecked Sendable {}
extension CMSampleBuffer: @unchecked Sendable {}
extension CXAnswerCallAction: @unchecked Sendable {}
extension CXSetHeldCallAction: @unchecked Sendable {}
extension CXSetMutedCallAction: @unchecked Sendable {}
extension KeyPath: @unchecked Sendable {}
extension Notification: @unchecked Sendable {}
extension RTCIceCandidate: @unchecked Sendable {}
extension RTCMediaStreamTrack: @unchecked Sendable {}
extension RTCSessionDescription: @unchecked Sendable {}
extension RTCStatisticsReport: @unchecked Sendable {}
extension WritableKeyPath: @unchecked Sendable {}
extension Published.Publisher: @unchecked Sendable {}
extension RTCVideoFrame: @unchecked Sendable {}
extension AnyPublisher: @unchecked Sendable {}
extension Publishers.Filter: @unchecked Sendable {}
/// Allows audio buffers to cross concurrency boundaries.
extension AVAudioPCMBuffer: @unchecked Sendable {}
#endif
