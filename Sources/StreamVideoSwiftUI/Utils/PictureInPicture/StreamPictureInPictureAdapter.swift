//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import UIKit

/// This class encapsulates the logic for managing picture-in-picture functionality during a video call. It tracks
/// changes in the call, updates related to call participants, and changes in the source view for Picture in
/// Picture display.
public final class StreamPictureInPictureAdapter: @unchecked Sendable {

    /// The active call.
    public var call: Call? {
        willSet { pictureInPictureContentAdapter.call = newValue }
    }

    /// The sourceView that will be used as an anchor/trigger for picture-in-picture (as required by AVKit).
    public var sourceView: UIView? {
        willSet {
            Task { @MainActor in
                if sourceView?.window == nil {
                    log.warning(
                        """
                        Picture-in-Picture requires its sourceView to be visible in 
                        a window.
                        """,
                        subsystems: .pictureInPicture
                    )
                } else {
                    pictureInPictureController?.sourceView = sourceView
                }
                if call == nil {
                    log.warning(
                        """
                        PictureInPicture adapter has received a sourceView but the required
                        call is nil. Please ensure that you provide a call instance in order
                        to activate correctly Picture-in-Picture.
                        """,
                        subsystems: .pictureInPicture
                    )
                }
            }
        }
    }

    private let pictureInPictureDataPipeline = PictureInPictureDataPipeline()

    /// The actual picture-in-picture controller.
    private lazy var pictureInPictureController = StreamPictureInPictureController(
        dataPipeline: pictureInPictureDataPipeline
    )

    private lazy var pictureInPictureContentAdapter = StreamPictureInPictureContentAdapter(
        dataPipeline: pictureInPictureDataPipeline
    )

    private let disposableBag = DisposableBag()

    init() {
        pictureInPictureController?
            .$isActive
            .removeDuplicates()
            .log(.debug, subsystems: .pictureInPicture) { "Picture-in-Picture contentProvider will receive isActive:\($0)." }
            .assign(to: \.isActive, onWeak: pictureInPictureContentAdapter)
            .store(in: disposableBag)

        pictureInPictureDataPipeline
            .contentPublisher
            .removeDuplicates()
            .log(.debug, subsystems: .pictureInPicture) { "Picture-in-Picture will now render content: \($0)" }
            .sink { _ in }
            .store(in: disposableBag)

        pictureInPictureDataPipeline
            .sizeEventPublisher
            .log(.debug, subsystems: .pictureInPicture) { "Picture-in-Picture generated size event: \($0)." }
            .sink { _ in }
            .store(in: disposableBag)
    }
}

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
enum StreamPictureInPictureAdapterKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamPictureInPictureAdapter = .init()
}

extension InjectedValues {
    /// Provides access to the `StreamPictureInPictureAdapter` class to the views and view models.
    public var pictureInPictureAdapter: StreamPictureInPictureAdapter {
        get {
            Self[StreamPictureInPictureAdapterKey.self]
        }
        set {
            Self[StreamPictureInPictureAdapterKey.self] = newValue
        }
    }
}
