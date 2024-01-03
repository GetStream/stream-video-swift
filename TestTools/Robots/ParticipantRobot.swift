//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

public class ParticipantRobot {
    private let videoBuddyUrlString = "http://localhost:5678/stream-video-buddy"
    private var screenSharingDuration: Int? = nil
    private var callRecordingDuration: Int? = nil
    private var userCount: Int = 1
    private var messageCount: Int = 1
    private var callDuration: Double = TestRunnerEnvironment.isCI ? 60 : 30
    private var _showWindow: Bool = false
    private var _printConsoleLogs: Bool = true
    private var _recordTestSession: Bool = true
    
    public enum Options: String {
        case withCamera = "camera"
        case withMicrophone = "mic"
        case beSilent = "silent"
    }
    
    public enum Actions: String {
        case shareScreen = "screen-share"
        case recordCall = "record"
        case sendMessage = "message"
    }
    
    public enum DebugActions: String {
        case showWindow = "show-window"
        case recordSession = "record-session"
        case printConsoleLogs = "verbose"
    }
    
    private enum Config: String {
        case callId = "call-id"
        case userCount = "user-count"
        case messageCount = "message-count"
        case callDuration = "duration"
        case screenSharingDuration = "screen-sharing-duration"
        case callRecordingDuration = "recording-duration"
    }

    @discardableResult
    func setScreenSharingDuration(_ duration: Int) -> Self {
        screenSharingDuration = duration
        return self
    }
    
    @discardableResult
    func setCallRecordingDuration(_ duration: Int) -> Self {
        callRecordingDuration = duration
        return self
    }
    
    @discardableResult
    func setCallDuration(_ duration: Double) -> Self {
        callDuration = duration
        return self
    }
    
    @discardableResult
    func setUserCount(_ count: Int) -> Self {
        userCount = count
        return self
    }
    
    @discardableResult
    func setMessageCount(_ count: Int) -> Self {
        messageCount = count
        return self
    }
    
    @discardableResult
    func showDebugWindow() -> Self {
        _showWindow = true
        return self
    }
    
    @discardableResult
    func printConsoleLogs() -> Self {
        _printConsoleLogs = true
        return self
    }
    
    @discardableResult
    func recordTestSession() -> Self {
        _recordTestSession = true
        return self
    }

    func joinCall(
        _ callId: String,
        options: [Options] = [],
        actions: [Actions] = [],
        async: Bool = true
    ) {
        var params: [String: Any] = [:]
        params[Config.callId.rawValue] = callId
        params[Config.userCount.rawValue] = userCount
        params[Config.messageCount.rawValue] = messageCount
        params[Config.callDuration.rawValue] = callDuration
        params[DebugActions.showWindow.rawValue] = _showWindow
        params[DebugActions.printConsoleLogs.rawValue] = _printConsoleLogs
        params[DebugActions.recordSession.rawValue] = _recordTestSession
        
        for option in options {
            params[option.rawValue] = true
        }
        
        for action in actions {
            params[action.rawValue] = true
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
        guard let apiUrl = URL(string: "\(videoBuddyUrlString)/?async=\(async)") else { return }
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }
}
