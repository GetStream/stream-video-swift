//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class PermissionsController_Tests: ControllerTestCase {
    
    func test_permissionsController_currentUserHasCapability() {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        let callSettingsResponse = MockResponseBuilder().makeCallSettingsResponse()
        let callSettings = CallSettingsInfo(
            callCapabilities: ["send-audio"],
            callSettings: callSettingsResponse,
            callInfo: .init(cId: callCid, backstage: false, blockedUsers: []),
            recording: false
        )
        callCoordinator.update(callSettings: callSettings)
        let permissionsController = PermissionsController(
            callCoordinatorController: callCoordinator,
            currentUser: user,
            callId: callId,
            callType: callType
        )
        
        // When
        let canSendAudio = permissionsController.currentUserHasCapability(.sendAudio)
        let canSendVideo = permissionsController.currentUserHasCapability(.sendVideo)
        
        // Then
        XCTAssert(canSendAudio == true)
        XCTAssert(canSendVideo == false)
    }
    
    func test_permissionsController_currentUserCanRequestPermissions() {
        // Given
        let callCoordinator = makeCallCoordinatorController()
        let callSettingsResponse = MockResponseBuilder().makeCallSettingsResponse()
        let callSettings = CallSettingsInfo(
            callCapabilities: ["send-audio"],
            callSettings: callSettingsResponse,
            callInfo: .init(cId: callCid, backstage: false, blockedUsers: []),
            recording: false
        )
        callCoordinator.update(callSettings: callSettings)
        let permissionsController = PermissionsController(
            callCoordinatorController: callCoordinator,
            currentUser: user,
            callId: callId,
            callType: callType
        )
        
        // When
        let canRequestAudio = permissionsController.currentUserCanRequestPermissions([.sendAudio])
        let canRequestVideo = permissionsController.currentUserCanRequestPermissions([.sendVideo])
        let canRequestScreenshare = permissionsController.currentUserCanRequestPermissions([.screenshare])
        
        // Then
        XCTAssert(canRequestAudio == true)
        XCTAssert(canRequestVideo == true)
        XCTAssert(canRequestScreenshare == false)
    }
    
    func test_permissionsController_canRequestPermissionsNoCallSettings() {
        // Given
        let permissionsController = PermissionsController(
            callCoordinatorController: makeCallCoordinatorController(),
            currentUser: user,
            callId: callId,
            callType: callType
        )
        
        // When
        let canRequestAudio = permissionsController.currentUserCanRequestPermissions([.sendAudio])
        
        // Then
        XCTAssert(canRequestAudio == false)
    }
    
    func test_permissionsController_requestPermissionWithoutCapabilityThrows() async throws {
        // Given
        let permissionsController = PermissionsController(
            callCoordinatorController: makeCallCoordinatorController(),
            currentUser: user,
            callId: callId,
            callType: callType
        )
        
        // Then
        do {
            try await permissionsController.request(
                permissions: [.sendAudio],
                callId: callId,
                callType: callType)
            XCTFail("Error should be thrown")
        } catch {
            XCTAssert(error is ClientError.MissingPermissions)
        }
    }
    
    func test_permissionsController_goLiveNoPermissionsThrows() async throws {
        // Given
        let permissionsController = PermissionsController(
            callCoordinatorController: makeCallCoordinatorController(),
            currentUser: user,
            callId: callId,
            callType: callType
        )
        
        // Then
        do {
            try await permissionsController.goLive(callId: callId, callType: callType)
            XCTFail("Error should be thrown")
        } catch {
            XCTAssert(error is ClientError.MissingPermissions)
        }
    }
    
    func test_permissionsController_stopLiveNoPermissionsThrows() async throws {
        // Given
        let permissionsController = PermissionsController(
            callCoordinatorController: makeCallCoordinatorController(),
            currentUser: user,
            callId: callId,
            callType: callType
        )
        
        // Then
        do {
            try await permissionsController.stopLive(callId: callId, callType: callType)
            XCTFail("Error should be thrown")
        } catch {
            XCTAssert(error is ClientError.MissingPermissions)
        }
    }
}
