//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import IOKit
#endif

extension SystemEnvironment {
    static let xStreamClientHeader: String = {
        "stream-video-swift-v\(version)|app=\(appName)|app_version=\(appVersion)|os=\(os) \(osVersion)|device_model=\(model)"
    }()

    static let clientDetails: Stream_Video_Sfu_Models_ClientDetails = {
        var result = Stream_Video_Sfu_Models_ClientDetails()
        result.sdk.type = .ios
        var versionComponents = version.split(separator: ".")
        result.sdk.major = versionComponents[safe: 0].map { String($0) } ?? ""
        result.sdk.minor = versionComponents[safe: 1].map { String($0) } ?? ""
        result.sdk.patch = versionComponents[safe: 2].map { String($0) } ?? ""

        result.device.name = model

        result.os.name = os
        result.os.version = osVersion

        return result
    }()

    private static var info: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }

    private static var appName: String {
        ((info["CFBundleDisplayName"] ?? info[kCFBundleIdentifierKey as String]) as? String) ?? "App name unavailable"
    }

    private static var appVersion: String {
        (info["CFBundleShortVersionString"] as? String) ?? "0"
    }

    private static var model: String {
        #if os(iOS)
        return deviceModelName
        #elseif os(macOS)
        return macModelIdentifier
        #endif
    }

    #if os(macOS)
    private static var macModelIdentifier: String = {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        var model = "MacOS device"

        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data,
            let deviceModelString = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) {
            model = deviceModelString
        }

        IOObjectRelease(service)
        return model
    }()
    #endif

    private static var osVersion: String {
        #if os(iOS)
        return CurrentDevice.currentValue.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    private static var os: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "MacOS"
        #endif
    }
}

extension Array {
    private subscript(safe index: Int) -> Element? {
        indices ~= index ? self[index] : nil
    }
}
