//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public class Sinatra {
    let baseUrl = "http://localhost:4567"

    var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
    
    enum ConnectionState: String {
        case on
        case off
    }
    
    func setConnection(state: ConnectionState) {
        Task {
            do {
                let url = URL(string: "\(baseUrl)/connection/\(state.rawValue)")!
                try await invokeSinatra(url: url)
            } catch {
                debugPrint(error)
            }
        }
    }
    
    func recordVideo(name: String, delete: Bool = false, stop: Bool = false) {
        Task {
            do {
                let json: [String: Any] = ["delete": delete, "stop": stop]
                let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
                let url = URL(string: "\(baseUrl)/record_video/\(udid)/\(name)")!
                try await invokeSinatra(url: url, body: json)
            } catch {
                debugPrint(error)
            }
        }
    }

    func openURL(_ url: URL) {
        Task {
            do {
                let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
                let json: [String: Any] = ["url": url.absoluteString, "udid": udid]
                let requestUrl = URL(string: "\(baseUrl)/open/url")!
                try await invokeSinatra(url: requestUrl, body: json)
            } catch {
                debugPrint(error)
            }
        }
        springboard.buttons["Open"].tapIfExists()
    }

    private func invokeSinatra(url: URL, body: [String: Any] = [:]) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await URLSession.shared.data(for: request)
    }
}
