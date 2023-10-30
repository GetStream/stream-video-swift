//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI
import GDPerformanceView_Swift
import StreamVideoSwiftUI

struct DebugMenu: View {

    @Injected(\.colors) var colors

    var title: String = ""

    @ObservedObject private var appState: AppState = .shared

    @State private var loggedInView: AppEnvironment.LoggedInView = AppEnvironment.loggedInView {
        didSet { AppEnvironment.loggedInView = loggedInView }
    }

    @State private var baseURL: AppEnvironment.BaseURL = AppEnvironment.baseURL {
        didSet {
            switch baseURL {
            case .staging:
                AppEnvironment.baseURL = .staging
                AppEnvironment.apiKey = .staging
            case .pronto:
                AppEnvironment.baseURL = .pronto
                AppEnvironment.apiKey = .staging
            case .production:
                AppEnvironment.baseURL = .production
                AppEnvironment.apiKey = .production
            }
            appState.unsecureRepository.save(baseURL: AppEnvironment.baseURL)
        }
    }

    @State private var supportedDeeplinks: [AppEnvironment.SupportedDeeplink] = AppEnvironment.supportedDeeplinks {
        didSet { AppEnvironment.supportedDeeplinks = supportedDeeplinks }
    }

    @State private var performanceTrackerVisibility: AppEnvironment.PerformanceTrackerVisibility = AppEnvironment.performanceTrackerVisibility {
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

    @State private var isLogsViewerVisible: Bool = false
    @State private var isSFUMigrationVisible: Bool = false

    var body: some View {
        Menu {
            makeMenu(
                for: [.production, .pronto, .staging],
                currentValue: baseURL,
                label: "Environment",
                isVisibleCondition: appState.activeCall == nil
            ) { self.baseURL = $0 }

            makeMultipleSelectMenu(
                for: [AppEnvironment.SupportedDeeplink.production, .staging],
                currentValues: .init(supportedDeeplinks),
                label: "Supported Deeplinks",
                isVisibleCondition: appState.activeCall == nil
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
                isVisibleCondition: appState.activeCall == nil
            ) { self.loggedInView = $0 }

            makeMenu(
                for: [.enabled, .disabled],
                currentValue: chatIntegration,
                label: "Chat Integration",
                isVisibleCondition: appState.activeCall == nil
            ) { self.chatIntegration = $0 }

            makeMenu(
                for: [.visible, .hidden],
                currentValue: performanceTrackerVisibility,
                label: "Performance Tracker",
                isVisibleCondition: true
            ) { self.performanceTrackerVisibility = $0 }

            makeButton(
                title: "Simulate migration",
                icon: "",
                binding: $isSFUMigrationVisible,
                isVisibleCondition: appState.activeCall != nil
            )

            makeButton(
                title: "Show logs",
                icon: "text.insert",
                binding: $isLogsViewerVisible,
                isVisibleCondition: true
            )
        } label: {
            Group {
                if title.isEmpty {
                    Image(systemName: "gearshape.fill")
                } else {
                    Label {
                        Text(title)
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .foregroundColor(colors.text)
            .sheet(isPresented: $isLogsViewerVisible) { NavigationView { MemoryLogViewer() } }
            .sheet(isPresented: $isSFUMigrationVisible) { if #available(iOS 15.0, *) { NavigationView { SessionMigrationView(activeCall: appState.activeCall) } } }
        }
    }

    @ViewBuilder
    private func makeMenu<Item: Debuggable>(
        for items: [Item],
        currentValue: Item,
        label: String,
        isVisibleCondition: @autoclosure () -> Bool,
        updater: @escaping (Item) -> Void
    ) -> some View {
        if isVisibleCondition() {
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
            } label: {
                Text(label)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func makeMultipleSelectMenu<Item: Debuggable>(
        for items: [Item],
        currentValues: Set<Item>,
        label: String,
        isVisibleCondition: @autoclosure () -> Bool,
        updater: @escaping (Item, Bool) -> Void
    ) -> some View {
        if isVisibleCondition() {
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
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func makeButton(
        title: String = "",
        icon: String = "",
        binding: Binding<Bool>,
        isVisibleCondition: @autoclosure () -> Bool
    ) -> some View {
        if isVisibleCondition() {
            Button {
                binding.wrappedValue = true
            } label: {
                Label {
                    if !title.isEmpty {
                        Text(title)
                    } else {
                        EmptyView()
                    }
                } icon: {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                    } else {
                        EmptyView()
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}

@available(iOS 15.0, *)
private struct SessionMigrationView: View {

    @Environment(\.dismiss) var dismiss
    @Injected(\.appearance) var appearance

    var activeCall: Call?

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 0) {
                Text("Current SFU")
                    .font(appearance.fonts.caption1)

                Text(activeCall?.state.statsReport?.datacenter ?? "N/A")
                    .multilineTextAlignment(.leading)
                    .font(appearance.fonts.bodyBold)
            }

            Button {
                resignFirstResponder()
                NotificationCenter.default.post(name: .init("force-migration"), object: nil)
                dismiss()
            } label: {
                CallButtonView(
                    title: "Migrate", isDisabled: false
                )
            }

        }
        .alignedToReadableContentGuide()
        .foregroundColor(appearance.colors.text)
        .navigationBarTitle("Session Migration")
    }
}
