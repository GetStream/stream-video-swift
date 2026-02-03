//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoStartRecordingButtonView: View {

    private enum RecordingType: CaseIterable {
        case composite
        case raw
        case individual

        var callRecordingType: CallRecordingType {
            switch self {
            case .composite:
                return .composite
            case .raw:
                return .raw
            case .individual:
                return .individual
            }
        }

        var title: String {
            switch self {
            case .composite:
                return "Composite"
            case .raw:
                return "Raw"
            case .individual:
                return "Individual"
            }
        }

        var icon: String {
            switch self {
            case .composite:
                return "rectangle.stack"
            case .raw:
                return "waveform"
            case .individual:
                return "person.2"
            }
        }
    }

    @ObservedObject var viewModel: CallViewModel

    @State private var isActive = false
    private var dismissMoreMenu: () -> Void

    init(
        viewModel: CallViewModel,
        _ dismissMoreMenu: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.dismissMoreMenu = dismissMoreMenu
    }

    var body: some View {
        Group {
            if isRecordingActive {
                DemoMoreControlListButtonView(
                    action: stopRecording,
                    label: "Stop recording"
                ) {
                    Image(systemName: "stop.circle")
                }
            } else {
                Menu {
                    ForEach(RecordingType.allCases, id: \.self) { recordingType in
                        buttonView(for: recordingType)
                    }
                } label: {
                    DemoMoreControlListButtonView(
                        action: { isActive.toggle() },
                        label: "Start recording"
                    ) {
                        Image(
                            systemName: isActive
                                ? "record.circle.fill"
                                : "record.circle"
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func buttonView(
        for recordingType: RecordingType
    ) -> some View {
        Button {
            execute(recordingType)
        } label: {
            Label {
                Text(recordingType.title)
            } icon: {
                Image(systemName: recordingType.icon)
            }
        }
    }

    private func execute(
        _ recordingType: RecordingType
    ) {
        Task {
            do {
                _ = try await viewModel.call?.startRecording(
                    recordingType: recordingType.callRecordingType
                )
            } catch {
                log.error(error)
            }
        }
        dismissMoreMenu()
    }

    private var isRecordingActive: Bool {
        viewModel.recordingState == .recording
    }

    private func stopRecording() {
        guard let recordingType = activeRecordingType() else {
            dismissMoreMenu()
            return
        }
        Task {
            do {
                _ = try await viewModel.call?.stopRecording(
                    recordingType: recordingType
                )
            } catch {
                log.error(error)
            }
        }
        dismissMoreMenu()
    }

    private func activeRecordingType() -> CallRecordingType? {
        guard let state = viewModel.call?.state else {
            return nil
        }

        if state.compositeRecordingStatus == true {
            return .composite
        }

        if state.rawRecordingStatus == true {
            return .raw
        }

        if state.individualRecordingStatus == true {
            return .individual
        }

        return nil
    }
}
