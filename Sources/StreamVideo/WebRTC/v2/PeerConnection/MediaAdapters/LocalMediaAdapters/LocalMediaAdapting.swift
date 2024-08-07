//
//  LocalMediaManaging.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 6/8/24.
//

import Foundation
import Combine

protocol LocalMediaAdapting {

    var subject: PassthroughSubject<TrackEvent, Never> { get }

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws

    func publish()

    func unpublish()

    func didUpdateCallSettings(_ settings: CallSettings) async throws
}
