import Foundation
import StreamKrispPlugin
import StreamKrispModels
import StreamWebRTC

public final class NoiseCancellationFilter {

    private let processor: KrispAudioProcessor
    public let name: String

    fileprivate init(model: KrispModel) {
        processor = .init(
            params: model.path,
            size: 10,
            isVad: model == .vad
        )
        self.name = model.rawValue
    }

    // MARK: - AudioFilter

    public func initialize(sampleRate: Int, channels: Int) {
        processor.initializeSession(
            withSampleRate: sampleRate,
            channels: channels
        )
    }

    public func process(_ buffer: inout RTCAudioBuffer) {
        processor.process(buffer)
    }

    public func release() {
        processor.destroy()
    }
}

extension NoiseCancellationFilter {
    public static let no1 = NoiseCancellationFilter(model: .c5ns20949d)
    public static let no2 = NoiseCancellationFilter(model: .c5swc9ac8f)
    public static let no3 = NoiseCancellationFilter(model: .c6fsced125)
}
