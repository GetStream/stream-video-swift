//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

#if swift(>=6.0)
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
#endif
