//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

struct RawStatsView: View {
    
    @Injected(\.fonts) var fonts
        
    var statsReport: CallStatsReport?
    
    var body: some View {
        NavigationView {
            if statsReport != nil {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        Text("Subscriber stats")
                            .font(fonts.headline)
                        ForEach(subscriberJsonStrings, id: \.self) { jsonString in
                            Text(jsonString)
                        }
                        Text("Publisher stats")
                            .font(fonts.headline)
                        ForEach(publisherJsonStrings, id: \.self) { jsonString in
                            Text(jsonString)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Call stats")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Stats not available")
            }
        }
    }
    
    var subscriberJsonStrings: [String] {
        guard let report = statsReport?.subscriberRawStats else { return [] }
        return jsonString(from: report)
    }
    
    var publisherJsonStrings: [String] {
        guard let report = statsReport?.publisherRawStats else { return [] }
        return jsonString(from: report)
    }
    
    func jsonString(from report: RTCStatisticsReport) -> [String] {
        let stats = report.statistics
        var result = [String]()
        for (key, value) in stats {
            if let jsonData = try? JSONSerialization.data(
                withJSONObject: value.values,
                options: [.prettyPrinted]
            ) {
                if let jsonString = String(
                    data: jsonData,
                    encoding: .ascii
                ) {
                    let text = "{\n\"\(key)\": \(jsonString)\n}"
                    result.append(text)
                }
            }
        }
        
        return result
    }
}
