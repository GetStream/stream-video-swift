//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal class DefaultAPI {

    /**
     Request permission
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter requestPermissionRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func requestPermission(
        type: String,
        id: String,
        requestPermissionRequest: RequestPermissionRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: RequestPermissionResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        requestPermissionWithRequestBuilder(type: type, id: id, requestPermissionRequest: requestPermissionRequest)
            .execute(apiResponseQueue) { result in
                switch result {
                case let .success(response):
                    completion(response.body, nil)
                case let .failure(error):
                    completion(nil, error)
                }
            }
    }

    /**
     Request permission
     - POST /call/{type}/{id}/request_permission
     - Request permission to perform an action
     - API Key:
       - type: apiKey Authorization
       - name: JWT
     - API Key:
       - type: apiKey api_key (QUERY)
       - name: api_key
     - API Key:
       - type: apiKey Stream-Auth-Type
       - name: stream-auth-type
     - parameter type: (path)
     - parameter id: (path)
     - parameter requestPermissionRequest: (body)
     - returns: RequestBuilder<RequestPermissionResponse>
     */
    internal class func requestPermissionWithRequestBuilder(
        type: String,
        id: String,
        requestPermissionRequest: RequestPermissionRequest
    ) -> RequestBuilder<RequestPermissionResponse> {
        var localVariablePath = "/call/{type}/{id}/request_permission"
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        localVariablePath = localVariablePath.replacingOccurrences(
            of: "{type}",
            with: typePostEscape,
            options: .literal,
            range: nil
        )
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        localVariablePath = localVariablePath.replacingOccurrences(of: "{id}", with: idPostEscape, options: .literal, range: nil)
        let localVariableURLString = OpenAPIClientAPI.basePath + localVariablePath
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: requestPermissionRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<RequestPermissionResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
            .getBuilder()

        return localVariableRequestBuilder.init(
            method: "POST",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }

    /**
     Update user permissions
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter updateUserPermissionsRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func updateUserPermissions(
        type: String,
        id: String,
        updateUserPermissionsRequest: UpdateUserPermissionsRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: UpdateUserPermissionsResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        updateUserPermissionsWithRequestBuilder(type: type, id: id, updateUserPermissionsRequest: updateUserPermissionsRequest)
            .execute(apiResponseQueue) { result in
                switch result {
                case let .success(response):
                    completion(response.body, nil)
                case let .failure(error):
                    completion(nil, error)
                }
            }
    }

    /**
     Update user permissions
     - POST /call/{type}/{id}/user_permissions
     - Updates user permissions
     - API Key:
       - type: apiKey Authorization
       - name: JWT
     - API Key:
       - type: apiKey api_key (QUERY)
       - name: api_key
     - API Key:
       - type: apiKey Stream-Auth-Type
       - name: stream-auth-type
     - parameter type: (path)
     - parameter id: (path)
     - parameter updateUserPermissionsRequest: (body)
     - returns: RequestBuilder<UpdateUserPermissionsResponse>
     */
    internal class func updateUserPermissionsWithRequestBuilder(
        type: String,
        id: String,
        updateUserPermissionsRequest: UpdateUserPermissionsRequest
    ) -> RequestBuilder<UpdateUserPermissionsResponse> {
        var localVariablePath = "/call/{type}/{id}/user_permissions"
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        localVariablePath = localVariablePath.replacingOccurrences(
            of: "{type}",
            with: typePostEscape,
            options: .literal,
            range: nil
        )
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        localVariablePath = localVariablePath.replacingOccurrences(of: "{id}", with: idPostEscape, options: .literal, range: nil)
        let localVariableURLString = OpenAPIClientAPI.basePath + localVariablePath
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: updateUserPermissionsRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<UpdateUserPermissionsResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
            .getBuilder()

        return localVariableRequestBuilder.init(
            method: "POST",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }
}
