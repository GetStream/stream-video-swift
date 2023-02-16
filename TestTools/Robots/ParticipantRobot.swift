//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest

public class ParticipantRobot {
    private let videoBuddyUrl = URL(string: "http://localhost:5678/stream-video-buddy")!
    private var screenSharingDuration: Int? = nil
    private var callRecordingDuration: Int? = nil
    private var callDuration: Int? = 15
    private var userCount: Int = 1
    
    public enum Options: String {
        case withCamera = "camera"
        case withMicrophone = "mic"
        case beSilent = "silent"
        case beFrozen = "frozen"
    }
    
    public enum Actions: String {
        case shareScreen = "screen-share"
        case recordCall = "record"
        case showWindow = "show-window"
    }
    
    private enum Config: String {
        case callId = "call-id"
        case userCount = "user-count"
        case callDuration = "duration"
        case screenSharingDuration = "screen-sharing-duration"
        case callRecordingDuration = "recording-duration"
    }

    func setScreenSharingDuration(_ duration: Int) -> Self {
        screenSharingDuration = duration
        return self
    }
    
    func setCallRecordingDuration(_ duration: Int) -> Self {
        callRecordingDuration = duration
        return self
    }
    
    func setCallDuration(_ duration: Int) -> Self {
        callDuration = duration
        return self
    }
    
    func setUserCount(_ count: Int) -> Self {
        userCount = count
        return self
    }

    func join(
        callId: String,
        options: [Options] = [],
        actions: [Actions] = [],
        async: Bool = true
    ) {
        var params: [String: Any] = [:]
        params[Config.callId.rawValue] = callId
        params[Config.userCount.rawValue] = userCount
        
        for option in options {
            params[option.rawValue] = true
        }
        
        for action in actions {
            params[action.rawValue] = true
        }
        
        if let callDuration {
            params[Config.callDuration.rawValue] = callDuration
        }
        
        if let callRecordingDuration {
            params[Config.callRecordingDuration.rawValue] = callRecordingDuration
        }
        
        if let screenSharingDuration {
            params[Config.screenSharingDuration.rawValue] = screenSharingDuration
        }
        
        invokeBuddy(with: params, async: async)
    }
       
    private func invokeBuddy(with params: [String: Any], async: Bool) {
        var request = URLRequest(url: videoBuddyUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        
        if async {
            URLSession.shared.dataTask(with: request).resume()
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
        }
    }
}
