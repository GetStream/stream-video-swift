//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
final class ParticipantStatsViewModel: ObservableObject {
    
    let call: Call
    let participant: CallParticipant
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var statsEntries = [StatsEntry]()
    @Published var allStatsShown = false {
        didSet {
            if allStatsShown && statsReport == nil {
                statsReport = call.state.statsReport
            } else if !allStatsShown {
                statsReport = nil
            }
        }
    }
    
    var statsReport: CallStatsReport?
    
    init(
        call: Call,
        participant: CallParticipant
    ) {
        self.call = call
        self.participant = participant
        subscribeToStatsUpdates()
    }

    private func subscribeToStatsUpdates() {
        call.state.$statsReport.sink { [weak self] statsReport in
            self?.handleStatsReport(statsReport)
        }
        .store(in: &cancellables)
    }
    
    private func handleStatsReport(_ report: CallStatsReport?) {
        guard let report,
              let trackId = participant.track?.trackId,
              let participantsStatsArray = report.participantsStats.report[trackId],
              !participantsStatsArray.isEmpty
        else {
            return
        }

        let participantStats = participantsStatsArray.sorted { lhs, rhs in
            lhs.frameWidth >= rhs.frameWidth && lhs.frameHeight >= rhs.frameHeight
        }[0]

        let isLocalUser = participant.sessionId == call.state.sessionId
        let datacenter = StatsEntry(
            title: "Region",
            value: report.datacenter
        )

        let resolution = StatsEntry(
            title: "Resolution",
            value: "\(participantStats.frameWidth) x \(participantStats.frameHeight)"
        )
        let codec = StatsEntry(title: "Codec", value: participantStats.codec)
        let bytes: StatsEntry
        if participant.id == call.state.sessionId {
            bytes = StatsEntry(
                title: "Bytes sent",
                value: "\(participantStats.bytesSent)"
            )
        } else {
            bytes = StatsEntry(
                title: "Received",
                value: "\(participantStats.bytesReceived)B"
            )
        }
        let fps = StatsEntry(
            title: "FPS",
            value: "\(participantStats.framesPerSecond)"
        )
        let jitter = StatsEntry(
            title: "Jitter",
            value: "\(participantStats.jitter)"
        )
        var entries = isLocalUser ? [datacenter] : []
        entries.append(contentsOf: [
            resolution,
            codec, fps,
            bytes, jitter
        ])

        if !participantStats.rid.isEmpty {
            let rid = StatsEntry(title: "rid", value: participantStats.rid)
            entries.append(rid)
        }
        
        statsEntries = entries
    }
    
    deinit {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
}

struct StatsEntry: Identifiable {
    var id: String {
        "\(title)-\(value)"
    }

    var title: String
    var value: String
}
