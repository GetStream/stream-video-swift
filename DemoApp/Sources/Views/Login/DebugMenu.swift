//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import GDPerformanceView_Swift
import StreamVideo
import SwiftUI

@MainActor
struct DebugMenu: View {

    @Injected(\.colors) var colors

    private var appState: AppState = .shared

    @State private var loggedInView: AppEnvironment.LoggedInView = AppEnvironment.loggedInView {
        didSet { AppEnvironment.loggedInView = loggedInView }
    }

    @State private var baseURL: AppEnvironment.BaseURL = AppEnvironment.baseURL {
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
            case let .custom(baseURL, apiKey, token):
                AppState.shared.apiKey = apiKey
                AppEnvironment.baseURL = .custom(baseURL: baseURL, apiKey: apiKey, token: token)
            default:
                break
            }
            appState.unsecureRepository.save(baseURL: AppEnvironment.baseURL)
        }
    }

    @State private var supportedDeeplinks: [AppEnvironment.SupportedDeeplink] = AppEnvironment.supportedDeeplinks {
        didSet { AppEnvironment.supportedDeeplinks = supportedDeeplinks }
    }

    @State private var performanceTrackerVisibility: AppEnvironment.PerformanceTrackerVisibility = AppEnvironment
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

    @State private var tokenExpiration: AppEnvironment.TokenExpiration = AppEnvironment.tokenExpiration {
        didSet { AppEnvironment.tokenExpiration = tokenExpiration }
    }

    @State private var callExpiration: AppEnvironment.CallExpiration = AppEnvironment.callExpiration {
        didSet { AppEnvironment.callExpiration = callExpiration }
    }

    @State private var sfuOverride: AppEnvironment.SFUOverride = AppEnvironment.sfuOverride {
        didSet {
            AppEnvironment.sfuOverride = sfuOverride
            switch sfuOverride {
            case .none:
                InjectedValues[\.sfuOverride] = nil
            case .custom(let string):
                InjectedValues[\.sfuOverride] = string
            }
        }
    }

    @State private var isLogsViewerVisible: Bool = false

    @State private var presentsCustomEnvironmentSetup: Bool = false

    @State private var customCallExpirationValue: Int = 0
    @State private var presentsCustomCallExpiration: Bool = false

    @State private var customTokenExpirationValue: Int = 0
    @State private var presentsCustomTokenExpiration: Bool = false

    @State private var customSFUOverride: String = ""
    @State private var presentsCustomSFUOverride: Bool = false

    @State private var autoLeavePolicy: AppEnvironment.AutoLeavePolicy = AppEnvironment.autoLeavePolicy {
        didSet { AppEnvironment.autoLeavePolicy = autoLeavePolicy }
    }

    var body: some View {
        Menu {
            makeMenu(
                for: [.demo, .pronto, .prontoStaging],
                currentValue: baseURL,
                additionalItems: { customEnvironmentView },
                label: "Environment"
            ) { self.baseURL = $0 }

            makeMenu(
                for: [.none],
                currentValue: sfuOverride,
                additionalItems: { customSFUOverrideView },
                label: "SFU Override"
            ) { sfuOverride = $0 }

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
                label: "LoggedIn View"
            ) { self.loggedInView = $0 }

            makeMenu(
                for: [.never, .oneMinute, .fiveMinutes, .thirtyMinutes],
                currentValue: tokenExpiration,
                additionalItems: { customTokenExpirationView },
                label: "Token Expiration"
            ) { self.tokenExpiration = $0 }

            makeMenu(
                for: [.never, .twoMinutes, .fiveMinutes, .tenMinutes],
                currentValue: callExpiration,
                additionalItems: { customCallExpirationView },
                label: "Call Expiration"
            ) { _ in self.callExpiration = .custom(10) }

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
                for: [.default, .lastParticipant],
                currentValue: autoLeavePolicy,
                label: "Auto Leave policy"
            ) { self.autoLeavePolicy = $0 }

            makeMenu(
                for: [.visible, .hidden],
                currentValue: performanceTrackerVisibility,
                label: "Performance Tracker"
            ) { self.performanceTrackerVisibility = $0 }

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
            title: "Enter SFU Override",
            placeholder: "URL",
            presentationBinding: $presentsCustomSFUOverride,
            valueBinding: $customSFUOverride,
            transformer: { $0 },
            action: {
                if customSFUOverride.isEmpty {
                    self.sfuOverride = .none
                } else {
                    self.sfuOverride = .custom(customSFUOverride)
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
                Label {
                    Text("Custom")
                } icon: {
                    EmptyView()
                }
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
                Label {
                    Text("Custom")
                } icon: {
                    EmptyView()
                }
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
                Label {
                    Text("Custom")
                } icon: {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var customSFUOverrideView: some View {
        Button {
            presentsCustomSFUOverride = true
        } label: {
            Label {
                Text("Custom")
            } icon: {
                switch AppEnvironment.sfuOverride {
                case .none:
                    EmptyView()
                case .custom:
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    @ViewBuilder
    private func makeMenu<Item: Debuggable>(
        for items: [Item],
        currentValue: Item,
        @ViewBuilder additionalItems: () -> some View = { EmptyView() },
        label: String,
        updater: @escaping (Item) -> Void
    ) -> some View {
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

    @ViewBuilder
    private func makeMultipleSelectMenu<Item: Debuggable>(
        for items: [Item],
        currentValues: Set<Item>,
        label: String,
        updater: @escaping (Item, Bool) -> Void
    ) -> some View {
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
        } label: {
            Text(label)
        }
    }
}
