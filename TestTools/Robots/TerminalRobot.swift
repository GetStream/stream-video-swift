//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class TerminalRobot {
    private let baseUrl = "http://localhost:4567"
    
    func recordVideo(name: String, delete: Bool = false, stop: Bool = false) {
        let json: [String: Any] = ["delete": delete, "stop": stop]
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
        let url = URL(string: "\(baseUrl)/record_video/\(udid)/\(name)")!
        invokeSinatra(url: url, body: json)
    }
    
    private func invokeSinatra(url: URL, body: [String: Any]) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        URLSession.shared.dataTask(with: request).resume()
    }
}
