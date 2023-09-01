//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

class VideoRendererFactory {
    private let queue = DispatchQueue(label: "io.getstream.videoRendererFactory")
    private(set) var views = [String: VideoRenderer]()
    private var pipRendererId: String?
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearViews),
            name: Notification.Name(CallNotification.callEnded),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleParticipantLeft),
            name: Notification.Name(CallNotification.participantLeft),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearViews),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    func view(for id: String, size: CGSize) -> VideoRenderer {
        if let view = views[id] {
            view.frame.size = size
            return view
        }
        let view = VideoRenderer(frame: .init(origin: .zero, size: size))
        views[id] = view
        return view
    }
    
    func view(for id: String, isScreensharing: Bool) -> VideoRenderer? {
        var viewId = id
        if isScreensharing {
            viewId = "\(id)-screenshare"
        }
        let view = views[viewId]
        self.pipRendererId = viewId
        return view
    }
    
    @objc func handleParticipantLeft(_ notification: Notification) {
        guard let participantId = notification.userInfo?["id"] as? String else {
            return
        }
        log.debug("Removing view for participant \(participantId)")
        queue.sync {
            views[participantId] = nil
        }
    }
    
    @objc func clearViews() {
        views = [String: VideoRenderer]()
    }
    
    func prepareForPictureInPicture() {
        var pipRenderer: VideoRenderer?
        var updated = [String: VideoRenderer]()
        if let pipRendererId {
            pipRenderer = views[pipRendererId]
            updated[pipRendererId] = pipRenderer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                pipRenderer?.track?.isEnabled = true
            })
        }
        views = updated
    }
}
