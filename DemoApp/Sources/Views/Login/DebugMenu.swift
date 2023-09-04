//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI
import GDPerformanceView_Swift

struct DebugMenu: View {

    @Injected(\.colors) var colors

    private var appState: AppState = .shared

    @State private var loggedInView: AppEnvironment.LoggedInView = AppEnvironment.loggedInView {
        didSet { AppEnvironment.loggedInView = loggedInView }
    }

    @State private var baseURL: AppEnvironment.BaseURL = AppEnvironment.baseURL {
        didSet {
            switch baseURL {
            case .staging:
                AppEnvironment.baseURL = .staging
                AppEnvironment.apiKey = .staging
            case .production:
                AppEnvironment.baseURL = .production
                AppEnvironment.apiKey = .production
            }
            appState.unsecureRepository.save(baseURL: AppEnvironment.baseURL)
        }
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

    var body: some View {
        Menu {
            makeMenu(
                for: [.production, .staging],
                currentValue: baseURL,
                label: "Environment"
            ) { self.baseURL = $0 }

            makeMenu(
                for: [.simple, .detailed],
                currentValue: loggedInView,
                label: "LoggedIn View"
            ) { self.loggedInView = $0 }

            makeMenu(
                for: [.enabled, .disabled],
                currentValue: chatIntegration,
                label: "Chat Integration"
            ) { self.chatIntegration = $0 }

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
        }.sheet(isPresented: $isLogsViewerVisible) {
            NavigationView {
                MemoryLogViewer()
            }
        }
    }

    @ViewBuilder
    private func makeMenu<Item: Debuggable>(
        for items: [Item],
        currentValue: Item,
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
        } label: {
            Text(label)
        }
    }
}

