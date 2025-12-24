//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

#if compiler(>=6.0)
extension AVAudioSession.Category: @retroactive CustomStringConvertible {}
extension AVAudioSession.CategoryOptions: @retroactive CustomStringConvertible {}
extension AVAudioSession.Mode: @retroactive CustomStringConvertible {}
extension AVAudioSession.PortOverride: @retroactive CustomStringConvertible {}
extension AVAudioSession.RouteChangeReason: @retroactive CustomStringConvertible {}
extension AVCaptureDevice.Position: @retroactive CustomStringConvertible {}
extension RTCIceConnectionState: @retroactive CustomStringConvertible {}
extension RTCIceGatheringState: @retroactive CustomStringConvertible {}
extension RTCPeerConnectionState: @retroactive CustomStringConvertible {}
extension RTCRtpTransceiverDirection: @retroactive CustomStringConvertible {}
extension RTCSdpType: @retroactive CustomStringConvertible {}
extension RTCSignalingState: @retroactive CustomStringConvertible {}
extension RTCDataChannelState: @retroactive CustomStringConvertible {}
extension RTCBundlePolicy: @retroactive CustomStringConvertible {}
extension RTCContinualGatheringPolicy: @retroactive CustomStringConvertible {}
extension CMSampleBuffer: @retroactive CustomStringConvertible {}
#else
extension AVAudioSession.Category: CustomStringConvertible {}
extension AVAudioSession.CategoryOptions: CustomStringConvertible {}
extension AVAudioSession.Mode: CustomStringConvertible {}
extension AVAudioSession.PortOverride: CustomStringConvertible {}
extension AVAudioSession.RouteChangeReason: CustomStringConvertible {}
extension AVCaptureDevice.Position: CustomStringConvertible {}
extension RTCIceConnectionState: CustomStringConvertible {}
extension RTCIceGatheringState: CustomStringConvertible {}
extension RTCPeerConnectionState: CustomStringConvertible {}
extension RTCRtpTransceiverDirection: CustomStringConvertible {}
extension RTCSdpType: CustomStringConvertible {}
extension RTCSignalingState: CustomStringConvertible {}
extension RTCDataChannelState: CustomStringConvertible {}
extension RTCBundlePolicy: CustomStringConvertible {}
extension RTCContinualGatheringPolicy: CustomStringConvertible {}
extension CMSampleBuffer: CustomStringConvertible {}
#endif
