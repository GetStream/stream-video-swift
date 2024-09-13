//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Factory for creating WebRTC join requests.
struct WebRTCJoinRequestFactory {
   /// Represents different types of connection for join requests.
   enum ConnectionType {
       case `default`
       case fastReconnect
       case migration(fromHostname: String)
       case rejoin(fromSessionID: String)

       /// Indicates if the connection type is a fast reconnect.
       var isFastReconnect: Bool {
           switch self {
           case .fastReconnect:
               return true
           default:
               return false
           }
       }
   }

   /// Builds a join request for WebRTC.
   /// - Parameters:
   ///   - connectionType: The type of connection for the join request.
   ///   - coordinator: The WebRTC coordinator.
   ///   - subscriberSdp: The subscriber's SDP.
   ///   - reconnectAttempt: The number of reconnect attempts.
   ///   - publisher: The RTC peer connection coordinator for publishing.
   ///   - file: The file where the method is called.
   ///   - function: The function where the method is called.
   ///   - line: The line number where the method is called.
   /// - Returns: A join request for the SFU.
   func buildRequest(
       with connectionType: ConnectionType,
       coordinator: WebRTCCoordinator,
       subscriberSdp: String,
       reconnectAttempt: UInt32,
       publisher: RTCPeerConnectionCoordinator?,
       file: StaticString = #file,
       function: StaticString = #function,
       line: UInt = #line
   ) async -> Stream_Video_Sfu_Event_JoinRequest {
       var result = Stream_Video_Sfu_Event_JoinRequest()
       result.clientDetails = SystemEnvironment.clientDetails
       result.sessionID = await coordinator.stateAdapter.sessionID
       result.subscriberSdp = subscriberSdp
       result.fastReconnect = connectionType.isFastReconnect
       result.token = await coordinator.stateAdapter.token
       if let reconnectDetails = await buildReconnectDetails(
           for: connectionType,
           coordinator: coordinator,
           reconnectAttempt: reconnectAttempt,
           publisher: publisher,
           file: file,
           function: function,
           line: line
       ) {
           result.reconnectDetails = reconnectDetails
       }

       return result
   }

   /// Builds reconnect details for the join request.
   /// - Parameters:
   ///   - connectionType: The type of connection for the join request.
   ///   - coordinator: The WebRTC coordinator.
   ///   - reconnectAttempt: The number of reconnect attempts.
   ///   - publisher: The RTC peer connection coordinator for publishing.
   ///   - file: The file where the method is called.
   ///   - function: The function where the method is called.
   ///   - line: The line number where the method is called.
   /// - Returns: Reconnect details for the join request.
   func buildReconnectDetails(
       for connectionType: ConnectionType,
       coordinator: WebRTCCoordinator,
       reconnectAttempt: UInt32,
       publisher: RTCPeerConnectionCoordinator?,
       file: StaticString = #file,
       function: StaticString = #function,
       line: UInt = #line
   ) async -> Stream_Video_Sfu_Event_ReconnectDetails? {
       var result = Stream_Video_Sfu_Event_ReconnectDetails()

       switch connectionType {
       case .default:
           break

       case .fastReconnect:
           result.announcedTracks = buildAnnouncedTracks(
               publisher,
               videoOptions: await coordinator.stateAdapter.videoOptions,
               file: file,
               function: function,
               line: line
           )
           result.subscriptions = await buildSubscriptionDetails(
               nil,
               coordinator: coordinator,
               file: file,
               function: function,
               line: line
           )
           result.strategy = .fast
           result.reconnectAttempt = reconnectAttempt

       case let .migration(fromHostname):
           result.announcedTracks = buildAnnouncedTracks(
               publisher,
               videoOptions: await coordinator.stateAdapter.videoOptions,
               file: file,
               function: function,
               line: line
           )
           result.fromSfuID = fromHostname
           result.subscriptions = await buildSubscriptionDetails(
               nil,
               coordinator: coordinator,
               file: file,
               function: function,
               line: line
           )
           result.strategy = .migrate
           result.reconnectAttempt = reconnectAttempt

       case let .rejoin(fromSessionID):
           result.announcedTracks = buildAnnouncedTracks(
               publisher,
               videoOptions: await coordinator.stateAdapter.videoOptions,
               file: file,
               function: function,
               line: line
           )
           result.subscriptions = await buildSubscriptionDetails(
               fromSessionID,
               coordinator: coordinator,
               file: file,
               function: function,
               line: line
           )
           result.strategy = .rejoin
           result.previousSessionID = fromSessionID
           result.reconnectAttempt = reconnectAttempt
       }

       return result
   }

   /// Builds announced tracks for the join request.
   /// - Parameters:
   ///   - publisher: The RTC peer connection coordinator for publishing.
   ///   - videoOptions: The video options for the tracks.
   ///   - file: The file where the method is called.
   ///   - function: The function where the method is called.
   ///   - line: The line number where the method is called.
   /// - Returns: An array of announced tracks.
   func buildAnnouncedTracks(
       _ publisher: RTCPeerConnectionCoordinator?,
       videoOptions: VideoOptions,
       file: StaticString = #file,
       function: StaticString = #function,
       line: UInt = #line
   ) -> [Stream_Video_Sfu_Models_TrackInfo] {
       var result = [Stream_Video_Sfu_Models_TrackInfo]()

       if let mid = publisher?.mid(for: .audio) {
           var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
           trackInfo.trackID = publisher?.localTrack(of: .audio)?.trackId ?? ""
           trackInfo.mid = mid
           trackInfo.trackType = .audio
           trackInfo.muted = publisher?.localTrack(of: .audio)?.isEnabled != true
           result.append(trackInfo)
       }

       if let mid = publisher?.mid(for: .video) {
           var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
           trackInfo.trackID = publisher?.localTrack(of: .video)?.trackId ?? ""
           trackInfo.layers = videoOptions
               .supportedCodecs
               .map { Stream_Video_Sfu_Models_VideoLayer($0) }
           trackInfo.mid = mid
           trackInfo.trackType = .video
           trackInfo.muted = publisher?.localTrack(of: .video)?.isEnabled != true
           result.append(trackInfo)
       }

       if let mid = publisher?.mid(for: .screenshare) {
           var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
           trackInfo.trackID = publisher?.localTrack(of: .screenshare)?.trackId ?? ""
           trackInfo.layers = [VideoCodec.screenshare]
               .map { Stream_Video_Sfu_Models_VideoLayer($0, fps: 15) }
           trackInfo.mid = mid
           trackInfo.trackType = .screenShare
           trackInfo.muted = publisher?.localTrack(of: .screenshare)?.isEnabled != true
           result.append(trackInfo)
       }

       return result
   }

   /// Builds subscription details for the join request.
   /// - Parameters:
   ///   - previousSessionID: The previous session ID, if any.
   ///   - coordinator: The WebRTC coordinator.
   ///   - file: The file where the method is called.
   ///   - function: The function where the method is called.
   ///   - line: The line number where the method is called.
   /// - Returns: An array of track subscription details.
   func buildSubscriptionDetails(
       _ previousSessionID: String?,
       coordinator: WebRTCCoordinator,
       file: StaticString = #file,
       function: StaticString = #function,
       line: UInt = #line
   ) async -> [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
       let sessionID = await coordinator.stateAdapter.sessionID
       return Array(await coordinator.stateAdapter.participants.values)
           .filter { $0.id != sessionID && $0.id != previousSessionID }
           .flatMap(\.trackSubscriptionDetails)
   }
}
