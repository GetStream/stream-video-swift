//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct MemoryLogViewer: View {
    
    @Injected(\.appearance) var appearance
    
    @State private var logs = LogQueue.queue.elements

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
