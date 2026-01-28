//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import GDPerformanceView_Swift
import StreamVideo
import SwiftUI

@MainActor
struct DebugMenu: View {

    @Injected(\.colors) var colors

    private var appState = AppState.shared

    @State private var loggedInView = AppEnvironment.loggedInView {
        didSet { AppEnvironment.loggedInView = loggedInView }
    }

    @State private var baseURL = AppEnvironment.baseURL {
        didSet {
            switch baseURL {
            case .pronto:
                AppState.shared.pushNotificationConfiguration = .default
                AppEnvironment.baseURL = .pronto
            case .demo:
                AppState.shared.pushNotificationConfiguration = .default
                AppEnvironment.baseURL = .demo
            case .prontoStaging:
                AppState.shared.pushNotificationConfiguration = .default
                AppEnvironment.baseURL = .prontoStaging
            case .prontoFrankfurtC2:
                AppState.shared.pushNotificationConfiguration = .default
                AppEnvironment.baseURL = .prontoFrankfurtC2
            case let .custom(baseURL, apiKey, token):
                AppState.shared.apiKey = apiKey
                AppEnvironment.baseURL = .custom(baseURL: baseURL, apiKey: apiKey, token: token)
            default:
                break
            }
            appState.unsecureRepository.save(baseURL: AppEnvironment.baseURL)
        }
    }

    @State private var supportedDeeplinks = AppEnvironment.supportedDeeplinks {
        didSet { AppEnvironment.supportedDeeplinks = supportedDeeplinks }
    }

    @State private var performanceTrackerVisibility = AppEnvironment
        .performanceTrackerVisibility {
        didSet {
            switch performanceTrackerVisibility {
            case .visible:
                PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance]
                PerformanceMonitor.shared().start()
                PerformanceMonitor.shared().show()
            case .hidden:
                PerformanceMonitor.shared().pause()
                PerformanceMonitor.shared().hide()
            }
        }
    }

    @State private var chatIntegration: AppEnvironment.ChatIntegration = AppEnvironment.chatIntegration {
        didSet { AppEnvironment.chatIntegration = chatIntegration }
    }

    @State private var pictureInPictureIntegration: AppEnvironment.PictureInPictureIntegration = AppEnvironment
        .pictureInPictureIntegration {
        didSet { AppEnvironment.pictureInPictureIntegration = pictureInPictureIntegration }
    }

    @State private var tokenExpiration = AppEnvironment.tokenExpiration {
        didSet { AppEnvironment.tokenExpiration = tokenExpiration }
    }

    @State private var callExpiration = AppEnvironment.callExpiration {
        didSet { AppEnvironment.callExpiration = callExpiration }
    }

    @State private var disconnectionTimeout = AppEnvironment.disconnectionTimeout {
        didSet { AppEnvironment.disconnectionTimeout = disconnectionTimeout }
    }

    @State private var isLogsViewerVisible = false

    @State private var presentsCustomEnvironmentSetup = false

    @State private var customCallExpirationValue = 0
    @State private var presentsCustomCallExpiration = false

    @State private var customTokenExpirationValue = 0
    @State private var presentsCustomTokenExpiration = false

    @State private var customDisconnectionTimeoutValue: TimeInterval = 0
    @State private var presentsCustomDisconnectionTimeout = false

    @State private var autoLeavePolicy = AppEnvironment.autoLeavePolicy {
        didSet { AppEnvironment.autoLeavePolicy = autoLeavePolicy }
    }

    @State private var preferredVideoCodec = AppEnvironment.preferredVideoCodec {
        didSet { AppEnvironment.preferredVideoCodec = preferredVideoCodec }
    }

    @State private var customPreferredCallType: String = ""
    @State private var presentsCustomPreferredCallType = false
    @State private var preferredCallType = AppEnvironment.preferredCallType {
        didSet { AppEnvironment.preferredCallType = preferredCallType?.isEmpty == true ? nil : preferredCallType }
    }

    @State private var availableCallTypes: [String] = AppEnvironment.availableCallTypes {
        didSet { AppEnvironment.availableCallTypes = availableCallTypes }
    }

    @State private var closedCaptionsIntegration: AppEnvironment.ClosedCaptionsIntegration = AppEnvironment
        .closedCaptionsIntegration {
        didSet {
            AppEnvironment.closedCaptionsIntegration = closedCaptionsIntegration
        }
    }

    @State private var audioSessionPolicy = AppEnvironment.audioSessionPolicy {
        didSet { AppEnvironment.audioSessionPolicy = audioSessionPolicy }
    }

    @State private var proximityPolicies = AppEnvironment.proximityPolicies {
        didSet { AppEnvironment.proximityPolicies = proximityPolicies }
    }

    @State private var availableClientCapabilities = ClientCapability.allCases
    @State private var preferredClientCapabilities = AppEnvironment.clientCapabilities {
        didSet { AppEnvironment.clientCapabilities = preferredClientCapabilities }
    }

    @State private var moderationVideoPolicy = AppEnvironment.moderationVideoPolicy {
        didSet { AppEnvironment.moderationVideoPolicy = moderationVideoPolicy }
    }

    @State private var customModerationVideoPolicyDuration: TimeInterval = 20
    @State private var presentsCustomModerationVideoPolicyDuration = false

    var body: some View {
        Menu {
            makeMenu(
                for: [.demo, .pronto, .prontoStaging, .prontoFrankfurtC2],
                currentValue: baseURL,
                additionalItems: { customEnvironmentView },
                label: "Environment",
                availableAfterLogin: false
            ) { self.baseURL = $0 }

            makeMultipleSelectMenu(
                for: AppEnvironment.SupportedDeeplink.allCases,
                currentValues: .init(supportedDeeplinks),
                label: "Supported Deeplinks"
            ) { item, isSelected in
                if isSelected {
                    supportedDeeplinks = supportedDeeplinks.filter { item != $0 }
                } else {
                    supportedDeeplinks.append(item)
                }
            }

            makeMenu(
                for: [.simple, .detailed],
                currentValue: loggedInView,
                label: "LoggedIn View",
                availableAfterLogin: false
            ) { self.loggedInView = $0 }

            makeMenu(
                for: [.never, .oneMinute, .fiveMinutes, .thirtyMinutes],
                currentValue: tokenExpiration,
                additionalItems: { customTokenExpirationView },
                label: "Token Expiration",
                availableAfterLogin: false
            ) { self.tokenExpiration = $0 }

            makeMenu(
                for: [.never, .twoMinutes, .fiveMinutes, .tenMinutes],
                currentValue: callExpiration,
                additionalItems: { customCallExpirationView },
                label: "Call Expiration"
            ) { self.callExpiration = $0 }

            makeMenu(
                for: [.enabled, .disabled],
                currentValue: chatIntegration,
                label: "Chat Integration"
            ) { self.chatIntegration = $0 }

            makeMenu(
                for: [.enabled, .disabled],
                currentValue: pictureInPictureIntegration,
                label: "Picture in Picture Integration"
            ) { self.pictureInPictureIntegration = $0 }

            makeMenu(
                for: [.enabled, .disabled],
                currentValue: closedCaptionsIntegration,
                label: "ClosedCaptions Integration"
            ) { self.closedCaptionsIntegration = $0 }

            makeMultipleSelectMenu(
                for: availableClientCapabilities,
                currentValues: preferredClientCapabilities ?? [],
                additionalItems: {
                    if preferredClientCapabilities != nil {
                        Divider()

                        Button {
                            self.preferredClientCapabilities = nil
                        } label: {
                            Text("Remove overrides")
                        }
                    } else {
                        EmptyView()
                    }
                },
                label: "Override Client Capabilities"
            ) { item, isSelected in
                if isSelected {
                    if let preferredClientCapabilities {
                        if preferredClientCapabilities.count == 1 {
                            self.preferredClientCapabilities = nil
                        } else {
                            self.preferredClientCapabilities = preferredClientCapabilities.filter { item != $0 }
                        }
                    }
                } else {
                    if preferredClientCapabilities == nil {
                        preferredClientCapabilities = Set<ClientCapability>()
                    }
                    preferredClientCapabilities?.insert(item)
                }
            }

            makeMenu(
                for: [.default, .ownCapabilities, .livestream],
                currentValue: audioSessionPolicy,
                label: "AudioSession policy"
            ) { self.audioSessionPolicy = $0 }

            makeMultipleSelectMenu(
                for: AppEnvironment.ProximityPolicyDebugConfiguration.allCases,
                currentValues: proximityPolicies,
                label: "Proximity policies"
            ) { item, isSelected in
                if isSelected {
                    proximityPolicies = proximityPolicies.filter { item != $0 }
                } else {
                    proximityPolicies.insert(item)
                }
            }

            makeMenu(
                for: [.default, .lastParticipant],
                currentValue: autoLeavePolicy,
                label: "Auto Leave policy"
            ) { self.autoLeavePolicy = $0 }

            makeMenu(
                for: [.blur(customModerationVideoPolicyDuration), .pixelate(customModerationVideoPolicyDuration)],
                currentValue: moderationVideoPolicy,
                additionalItems: { customModerationVideoView },
                label: "Moderation Video Policy"
            ) { self.moderationVideoPolicy = $0 }

            RenderingOptions()

            makeMenu(
                for: [.never, .twoMinutes],
                currentValue: disconnectionTimeout,
                additionalItems: { customDisconnectionTimeoutView },
                label: "Disconnection Timeout"
            ) { self.disconnectionTimeout = $0 }

            makeMenu(
                for: availableCallTypes,
                currentValue: preferredCallType ?? "",
                additionalItems: {
                    Divider()
                    customPreferredCallTypeView
                    if preferredCallType != nil {
                        Divider()
                        Button {
                            self.preferredCallType = nil
                        } label: {
                            Label {
                                Text("Clear")
                            } icon: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                },
                label: "Preferred CallType"
            ) { self.preferredCallType = $0 }

            makeMenu(
                for: [.h264, .vp8, .vp9, .av1],
                currentValue: preferredVideoCodec,
                label: "Preferred Video Codec"
            ) { self.preferredVideoCodec = $0 }

            makeMenu(
                for: [.visible, .hidden],
                currentValue: performanceTrackerVisibility,
                label: "Performance Tracker"
            ) { self.performanceTrackerVisibility = $0 }

            makeMenu(
                for: [.debug, .info, .warning, .error],
                currentValue: LogConfig.level,
                label: "Log Level"
            ) { LogConfig.level = $0 }

            makeMenu(
                for: [.none, .validFilesOnly, .all],
                currentValue: Logger.WebRTC.mode,
                label: "WebRTC Logs"
            ) { Logger.WebRTC.mode = $0 }

            Button {
                isLogsViewerVisible = true
            } label: {
                Label {
                    Text("Show logs")
                } icon: {
                    Image(systemName: "text.insert")
                }
            }

        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundColor(colors.text)
        }
        .sheet(isPresented: $isLogsViewerVisible) {
            NavigationView {
                MemoryLogViewer()
            }
        }
        .sheet(isPresented: $presentsCustomEnvironmentSetup) {
            NavigationView {
                if case let .custom(baseURL, apiKey, token) = AppEnvironment.baseURL {
                    DemoCustomEnvironmentView(
                        baseURL: baseURL,
                        apiKey: apiKey,
                        token: token
                    ) {
                        self.baseURL = .custom(baseURL: $0, apiKey: $1, token: $2)
                        presentsCustomEnvironmentSetup = false
                    }
                } else {
                    DemoCustomEnvironmentView(
                        baseURL: .demo,
                        apiKey: "",
                        token: ""
                    ) {
                        self.baseURL = .custom(baseURL: $0, apiKey: $1, token: $2)
                        presentsCustomEnvironmentSetup = false
                    }
                }
            }
        }
        .alertWithTextField(
            title: "Enter Call expiration interval in seconds",
            placeholder: "Interval",
            presentationBinding: $presentsCustomCallExpiration,
            valueBinding: $customCallExpirationValue,
            transformer: { Int($0) ?? 0 },
            action: { self.callExpiration = .custom(customCallExpirationValue) }
        )
        .alertWithTextField(
            title: "Enter Token expiration interval in seconds",
            placeholder: "Interval",
            presentationBinding: $presentsCustomTokenExpiration,
            valueBinding: $customTokenExpirationValue,
            transformer: { Int($0) ?? 0 },
            action: { self.tokenExpiration = .custom(customTokenExpirationValue) }
        )
        .alertWithTextField(
            title: "Enter disconnection timeout in seconds",
            placeholder: "Interval",
            presentationBinding: $presentsCustomDisconnectionTimeout,
            valueBinding: $customDisconnectionTimeoutValue,
            transformer: { TimeInterval($0) ?? 0 },
            action: { self.disconnectionTimeout = .custom(customDisconnectionTimeoutValue) }
        )
        .alertWithTextField(
            title: "Enter call type",
            placeholder: "Call Type",
            presentationBinding: $presentsCustomPreferredCallType,
            valueBinding: $customPreferredCallType,
            transformer: { $0 },
            action: {
                self.availableCallTypes.append(customPreferredCallType)
                self.preferredCallType = customPreferredCallType
            }
        )
        .alertWithTextField(
            title: "Enter moderation policy duration in seconds",
            placeholder: "Duration",
            presentationBinding: $presentsCustomModerationVideoPolicyDuration,
            valueBinding: $customModerationVideoPolicyDuration,
            transformer: { TimeInterval($0) ?? 0 },
            action: {
                switch moderationVideoPolicy {
                case .blur:
                    moderationVideoPolicy = .blur(customModerationVideoPolicyDuration)
                case .pixelate:
                    moderationVideoPolicy = .pixelate(customModerationVideoPolicyDuration)
                }
            }
        )
    }

    @ViewBuilder
    private var customEnvironmentView: some View {
        if case let .custom(_, apiKey, _) = AppEnvironment.baseURL {
            Button {
                presentsCustomEnvironmentSetup = true
            } label: {
                Label {
                    Text("Custom (\(apiKey))")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
        } else {
            Button {
                presentsCustomEnvironmentSetup = true
            } label: {
                Text("Custom")
            }
        }
    }

    @ViewBuilder
    private var customTokenExpirationView: some View {
        if case let .custom(value) = AppEnvironment.tokenExpiration {
            Button {
                presentsCustomTokenExpiration = true
            } label: {
                Label {
                    Text("Custom (\(value)\")")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
        } else {
            Button {
                presentsCustomTokenExpiration = true
            } label: {
                Text("Custom")
            }
        }
    }

    @ViewBuilder
    private var customCallExpirationView: some View {
        if case let .custom(value) = AppEnvironment.callExpiration {
            Button {
                presentsCustomCallExpiration = true
            } label: {
                Label {
                    Text("Custom (\(value)\")")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
        } else {
            Button {
                presentsCustomCallExpiration = true
            } label: {
                Text("Custom")
            }
        }
    }

    @ViewBuilder
    private var customDisconnectionTimeoutView: some View {
        if case let .custom(value) = AppEnvironment.disconnectionTimeout {
            Button {
                presentsCustomDisconnectionTimeout = true
            } label: {
                Label {
                    Text("Custom (\(value)\")")
                } icon: {
                    Image(systemName: "checkmark")
                }
            }
        } else {
            Button {
                presentsCustomDisconnectionTimeout = true
            } label: {
                Text("Custom")
            }
        }
    }

    @ViewBuilder
    private var customPreferredCallTypeView: some View {
        Button {
            presentsCustomPreferredCallType = true
        } label: {
            Label {
                Text("Add")
            } icon: {
                Image(systemName: "plus")
            }
        }
    }

    @ViewBuilder
    private var customModerationVideoView: some View {
        Button {
            presentsCustomModerationVideoPolicyDuration = true
        } label: {
            Text("Duration")
        }
    }

    @ViewBuilder
    private func makeMenu<Item: Debuggable>(
        for items: [Item],
        currentValue: Item,
        @ViewBuilder additionalItems: @escaping () -> some View = { EmptyView() },
        label: String,
        availableAfterLogin: Bool = true,
        updater: @escaping (Item) -> Void
    ) -> some View {
        DebugMenuItemView(
            label: label,
            availableAfterLogin: availableAfterLogin,
            items: items,
            currentValue: currentValue,
            additionalItems: additionalItems,
            updater: updater
        )

        if !availableAfterLogin, appState.userState == .loggedIn {
            EmptyView()
        } else {
            Menu {
                ForEach(items, id: \.self) { item in
                    Button {
                        updater(item)
                    } label: {
                        Label {
                            Text(item.title)
                        } icon: {
                            currentValue == item
                                ? AnyView(Image(systemName: "checkmark"))
                                : AnyView(EmptyView())
                        }
                    }
                }

                additionalItems()
            } label: {
                Text(label)
            }
        }
    }

    @ViewBuilder
    private func makeMultipleSelectMenu<Item: Debuggable>(
        for items: [Item],
        currentValues: Set<Item>,
        @ViewBuilder additionalItems: () -> some View = { EmptyView() },
        label: String,
        availableAfterLogin: Bool = true,
        updater: @escaping (Item, Bool) -> Void
    ) -> some View {
        if !availableAfterLogin, appState.userState == .loggedIn {
            EmptyView()
        } else {
            Menu {
                ForEach(items, id: \.self) { item in
                    Button {
                        updater(item, currentValues.contains(item))
                    } label: {
                        Label {
                            Text(item.title)
                        } icon: {
                            currentValues.contains(item)
                                ? AnyView(Image(systemName: "checkmark"))
                                : AnyView(EmptyView())
                        }
                    }
                }
                additionalItems()
            } label: {
                Text(label)
            }
        }
    }
}

extension LogLevel: Debuggable {
    var title: String {
        switch self {
        case .debug:
            return "Debug"

        case .info:
            return "Info"

        case .warning:
            return "Warning"

        case .error:
            return "Error"
        }
    }
}
