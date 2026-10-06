//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct MemoryLogViewer: View {
    
    @Injected(\.appearance) var appearance

    @Binding var isPresented: Bool
    
    @State private var logs: [LogDetails] = []
    @State private var query = ""
    @State private var isSharePresented = false
    @State private var logFileURL: URL?
    @State private var exportTask: Task<Void, Never>?
    @State private var exportError: String?

    var body: some View {
        List {
            ForEach(logs, id: \.date) { entry in
                NavigationLink {
                    MemoryLogEntryViewer(entry: entry)
                } label: {
                    makeEntryView(for: entry)
                }
            }
        }
        .navigationTitle("Logs Viewer")
        .task(id: query) {
            while !Task.isCancelled {
                let entries = LogQueue.queue.elements
                logs = query.isEmpty
                    ? entries
                    : entries.filter { $0.message.contains(query) }
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButtonView
            }
        }
        .modifier(SearchableModifier(query: $query))
        .sheet(isPresented: $isSharePresented) {
            if let logFileURL = logFileURL {
                ShareActivityView(activityItems: [logFileURL])
            }
        }
        .onDisappear {
            if !isPresented {
                logs.removeAll(keepingCapacity: false)
            }
            exportTask?.cancel()
            deleteTemporaryLogFile()
        }
        .onChange(of: isSharePresented) { isPresented in
            if !isPresented {
                // Delete the file after sharing is complete
                deleteTemporaryLogFile()
            }
        }
        .alert(isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Alert(
                title: Text("Unable to export logs"),
                message: Text(exportError ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    var shareButtonView: some View {
        Button {
            createAndShareLogFile()
        } label: {
            Image(systemName: "square.and.arrow.up.fill")
        }
        .disabled(exportTask != nil)
    }
    
    private func createAndShareLogFile() {
        exportTask = Task { @MainActor in
            defer { exportTask = nil }
            deleteTemporaryLogFile()
            do {
                let fileURL = try await LogQueue.createLogFile()
                guard !Task.isCancelled else {
                    LogQueue.deleteTemporaryLogFile(at: fileURL)
                    return
                }
                logFileURL = fileURL
                isSharePresented = true
            } catch {
                if !Task.isCancelled {
                    exportError = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteTemporaryLogFile() {
        if let fileURL = logFileURL {
            logFileURL = nil
            LogQueue.deleteTemporaryLogFile(at: fileURL)
        }
    }

    @ViewBuilder
    func makeEntryView(for entry: LogDetails) -> some View {
        let (iconName, iconColor): (String, Color) = {
            switch entry.level {
            case .debug:
                return ("ladybug", appearance.colors.text)
            case .info:
                return ("info.circle", Color.blue)
            case .warning:
                return ("exclamationmark.circle", Color.yellow)
            case .error:
                return ("x.circle", appearance.colors.accentRed)
            }
        }()
        
        Label {
            Text(entry.message)
                .font(appearance.fonts.body)
                .foregroundColor(appearance.colors.text)
                .lineLimit(3)
        } icon: {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
        }
    }
}

struct SearchableModifier: ViewModifier {
    
    @Binding var query: String
    
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .searchable(text: $query)
        } else {
            content
        }
    }
}

struct MemoryLogEntryViewer: View {
    
    @Injected(\.appearance) var appearance
    
    var entry: LogDetails
    
    var body: some View {
        Label {
            ScrollView {
                Text(entry.message)
                    .font(appearance.fonts.body)
                    .foregroundColor(appearance.colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } icon: {
            iconView
        }
        .padding(.horizontal)
    }
    
    private var iconView: some View {
        VStack(spacing: 16) {
            switch entry.level {
            case .debug:
                Image(systemName: "ladybug")
                    .foregroundColor(appearance.colors.text)
            case .info:
                Image(systemName: "info.circle")
                    .foregroundColor(Color.blue)
            case .warning:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(Color.yellow)
            case .error:
                Image(systemName: "x.circle")
                    .foregroundColor(appearance.colors.accentRed)
            }
            
            copyMessageView
        }
    }
    
    private var copyMessageView: some View {
        Button {
            UIPasteboard.general.string = entry.message
        } label: {
            Image(systemName: "doc.on.doc")
                .foregroundColor(Color.blue)
        }
    }
}
