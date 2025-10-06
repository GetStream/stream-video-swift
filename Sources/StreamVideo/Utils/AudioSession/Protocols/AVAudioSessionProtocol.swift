//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

enum StereoAudioPosition {
    case front
    case back

    var rawValue: AVAudioSession.Orientation {
        switch self {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

extension StreamDeviceOrientation {

    var stereoOrientation: AVAudioSession.StereoOrientation {
        switch self {
        case let .portrait(isUpsideDown):
            return isUpsideDown ? .portraitUpsideDown : .portrait
        case let .landscape(isLeft):
            return isLeft ? .landscapeLeft : .landscapeRight
        }
    }
}

protocol AVAudioSessionProtocol {

    var builtInMicInput: AVAudioSessionPortDescription? { get }

    /// Configures the audio session category and options.
    /// - Parameters:
    ///   - category: The audio category (e.g., `.playAndRecord`).
    ///   - mode: The audio mode (e.g., `.videoChat`).
    ///   - categoryOptions: The options for the category (e.g., `.allowBluetoothHFP`).
    /// - Throws: An error if setting the category fails.
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) throws

    /// Overrides the audio output port (e.g., to speaker).
    /// - Parameter port: The output port override.
    /// - Throws: An error if overriding fails.
    func setOverrideOutputAudioPort(
        _ port: AVAudioSession.PortOverride
    ) throws

    /// The method uses a slightly different name to avoid compiler not being able to automatically
    /// fulfil the conformance to this protocol.
    func setIsActive(_ active: Bool) throws

    func enableBuiltInMic() throws

    func setStereoAudioPosition(
        _ position: StereoAudioPosition,
        deviceOrientation: StreamDeviceOrientation
    ) throws

    func resetInputPreferences() throws
}

extension AVAudioSession: AVAudioSessionProtocol {

    var builtInMicInput: AVAudioSessionPortDescription? {
        availableInputs?.first { $0.portType == .builtInMic }
    }

    func setIsActive(_ active: Bool) throws {
        try setActive(active)
    }

    func setCategory(
        _ category: Category,
        mode: Mode,
        with categoryOptions: CategoryOptions
    ) throws {
        try setCategory(
            category,
            mode: mode,
            options: categoryOptions
        )
    }

    func setOverrideOutputAudioPort(_ port: PortOverride) throws {
        try overrideOutputAudioPort(port)
    }

    func enableBuiltInMic() throws {
        // Find the built-in microphone input.
        guard
            let builtInMicInput = builtInMicInput
        else {
            throw ClientError("The device must have a built-in microphone.")
        }

        // Make the built-in microphone input the preferred input.
        do {
            try setPreferredInput(builtInMicInput)
        } catch {
            throw ClientError("Unable to set the built-in mic as the preferred input. \(error)")
        }
    }

    func setStereoAudioPosition(
        _ position: StereoAudioPosition,
        deviceOrientation: StreamDeviceOrientation
    ) throws {
        guard #available(iOS 14.0, *) else {
            throw ClientError("Stereo input isn't supported.")
        }

        // Find the built-in microphone input's data sources,
        // and select the one that matches the specified name.
        guard
            let preferredInput = self.preferredInput,
            let dataSources = preferredInput.dataSources,
            let newDataSource = dataSources.first(where: { $0.dataSourceName == position.rawValue.rawValue }),
            let supportedPolarPatterns = newDataSource.supportedPolarPatterns
        else {
            throw ClientError("No suitable data source found.")
        }

        let isStereoSupported = supportedPolarPatterns.contains(.stereo)

        // If the data source supports stereo, set it as the preferred polar pattern.
        if isStereoSupported {
            // Set the preferred polar pattern to stereo.
            try newDataSource.setPreferredPolarPattern(.stereo)
        }

        // Set the preferred data source and polar pattern.
        try preferredInput.setPreferredDataSource(newDataSource)

        // Update the input orientation to match the current user interface orientation.
        try setPreferredInputOrientation(deviceOrientation.stereoOrientation)
    }

    func resetInputPreferences() throws {
        try setPreferredInput(nil)
    }
}
