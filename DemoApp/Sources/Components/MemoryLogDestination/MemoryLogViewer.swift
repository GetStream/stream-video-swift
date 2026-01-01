//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct MemoryLogViewer: View {
    
    @Injected(\.appearance) var appearance
    
    @State private var logs = LogQueue.queue.elements
    @State private var isSharePresented = false
    @State private var logFileURL: URL?

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                shareButtonView
            }
        }
        .modifier(
            SearchableModifier { query in
                if query.isEmpty {
                    logs = LogQueue.queue.elements
                } else {
                    logs = LogQueue.queue
                        .elements
                        .filter { $0.message.contains(query) }
                }
            }
        )
        .sheet(isPresented: $isSharePresented) {
            if let logFileURL = logFileURL {
                ShareActivityView(activityItems: [logFileURL])
            }
        }
        .onDisappear {
            deleteTemporaryLogFile()
        }
        .onChange(of: isSharePresented) { isPresented in
            if !isPresented {
                // Delete the file after sharing is complete
                deleteTemporaryLogFile()
            }
        }
    }

    @ViewBuilder
    var shareButtonView: some View {
        Button {
            createAndShareLogFile()
        } label: {
            Image(systemName: "square.and.arrow.up.fill")
        }
    }
    
    private func createAndShareLogFile() {
        Task {
            // Delete any existing temporary file first
            deleteTemporaryLogFile()

            // Create a temporary file URL
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            let fileName = "stream_video_logs_\(Date().timeIntervalSince1970).txt"
            let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)

            // Create log content

            // Add all logs to the content
            let logs = LogQueue.queue.elements
            let logContent = """
            Stream Video Logs - Generated: \(Date())
            \(logs.reversed().map { "\($0.level) - [\($0.fileName):\($0.lineNumber):\($0.functionName)] \($0.message)" }
                .joined(separator: "\n")
            )
            """

            // Write to file
            do {
                try logContent.write(to: fileURL, atomically: true, encoding: .utf8)
                self.logFileURL = fileURL
                Task { @MainActor in
                    self.isSharePresented = true
                }
            } catch {
                print("Error creating log file: \(error)")
            }
        }
    }
    
    private func deleteTemporaryLogFile() {
        if let fileURL = logFileURL {
            do {
                try FileManager.default.removeItem(at: fileURL)
                logFileURL = nil
                print("Temporary log file deleted successfully")
            } catch {
                print("Error deleting temporary log file: \(error)")
            }
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
    
    @State var query: String = ""
    var searchCompletionHandler: (String) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .searchable(text: $query)
                .onChange(of: query) { searchCompletionHandler($0) }
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
