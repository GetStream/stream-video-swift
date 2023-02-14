//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal class VideoCallsAPI {

    /**
     End call
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func endCall(
        type: String,
        id: String,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: EndCallResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        endCallWithRequestBuilder(type: type, id: id).execute(apiResponseQueue) { result in
            switch result {
            case let .success(response):
                completion(response.body, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

    /**
     End call
     - POST /call/{type}/{id}/mark_ended
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
     - returns: RequestBuilder<EndCallResponse>
     */
    internal class func endCallWithRequestBuilder(type: String, id: String) -> RequestBuilder<EndCallResponse> {
        var localVariablePath = "/call/{type}/{id}/mark_ended"
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
        let localVariableParameters: [String: Any]? = nil

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<EndCallResponse>.Type = OpenAPIClientAPI.requestBuilderFactory.getBuilder()

        return localVariableRequestBuilder.init(
            method: "POST",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }

    /**
     Get Call Edge Server
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter getCallEdgeServerRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func getCallEdgeServer(
        type: String,
        id: String,
        getCallEdgeServerRequest: GetCallEdgeServerRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: GetCallEdgeServerResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        getCallEdgeServerWithRequestBuilder(type: type, id: id, getCallEdgeServerRequest: getCallEdgeServerRequest)
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
     Get Call Edge Server
     - POST /call/{type}/{id}/get_edge_server
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
     - parameter getCallEdgeServerRequest: (body)
     - returns: RequestBuilder<GetCallEdgeServerResponse>
     */
    internal class func getCallEdgeServerWithRequestBuilder(
        type: String,
        id: String,
        getCallEdgeServerRequest: GetCallEdgeServerRequest
    ) -> RequestBuilder<GetCallEdgeServerResponse> {
        var localVariablePath = "/call/{type}/{id}/get_edge_server"
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
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: getCallEdgeServerRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<GetCallEdgeServerResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
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
     Get or create a call
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter getOrCreateCallRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func getOrCreateCall(
        type: String,
        id: String,
        getOrCreateCallRequest: GetOrCreateCallRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: GetOrCreateCallResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        getOrCreateCallWithRequestBuilder(type: type, id: id, getOrCreateCallRequest: getOrCreateCallRequest)
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
     Get or create a call
     - POST /call/{type}/{id}
     - Gets or creates a new call
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
     - parameter getOrCreateCallRequest: (body)
     - returns: RequestBuilder<GetOrCreateCallResponse>
     */
    internal class func getOrCreateCallWithRequestBuilder(
        type: String,
        id: String,
        getOrCreateCallRequest: GetOrCreateCallRequest
    ) -> RequestBuilder<GetOrCreateCallResponse> {
        var localVariablePath = "/call/{type}/{id}"
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
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: getOrCreateCallRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<GetOrCreateCallResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
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
     Join call
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter joinCallRequest: (body)
     - parameter connectionId: (query)  (optional)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func joinCall(
        type: String,
        id: String,
        joinCallRequest: JoinCallRequest,
        connectionId: String? = nil,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: JoinCallResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        joinCallWithRequestBuilder(type: type, id: id, joinCallRequest: joinCallRequest, connectionId: connectionId)
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
     Join call
     - POST /join_call/{type}/{id}
     - Request to join a call
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
     - parameter joinCallRequest: (body)
     - parameter connectionId: (query)  (optional)
     - returns: RequestBuilder<JoinCallResponse>
     */
    internal class func joinCallWithRequestBuilder(
        type: String,
        id: String,
        joinCallRequest: JoinCallRequest,
        connectionId: String? = nil
    ) -> RequestBuilder<JoinCallResponse> {
        var localVariablePath = "/join_call/{type}/{id}"
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
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: joinCallRequest)

        var localVariableUrlComponents = URLComponents(string: localVariableURLString)
        localVariableUrlComponents?.queryItems = APIHelper.mapValuesToQueryItems([
            "connection_id": (wrappedValue: connectionId?.encodeToJSON(), isExplode: false)
        ])

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<JoinCallResponse>.Type = OpenAPIClientAPI.requestBuilderFactory.getBuilder()

        return localVariableRequestBuilder.init(
            method: "POST",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }

    /**
     Mute users
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter muteUsersRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func muteUsers(
        type: String,
        id: String,
        muteUsersRequest: MuteUsersRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: MuteUsersResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        muteUsersWithRequestBuilder(type: type, id: id, muteUsersRequest: muteUsersRequest).execute(apiResponseQueue) { result in
            switch result {
            case let .success(response):
                completion(response.body, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

    /**
     Mute users
     - POST /call/{type}/{id}/mute_users
     - Mutes users in a call
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
     - parameter muteUsersRequest: (body)
     - returns: RequestBuilder<MuteUsersResponse>
     */
    internal class func muteUsersWithRequestBuilder(
        type: String,
        id: String,
        muteUsersRequest: MuteUsersRequest
    ) -> RequestBuilder<MuteUsersResponse> {
        var localVariablePath = "/call/{type}/{id}/mute_users"
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
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: muteUsersRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<MuteUsersResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
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
     Update Call
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter updateCallRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func nameVideoUpdateCall(
        type: String,
        id: String,
        updateCallRequest: UpdateCallRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: UpdateCallResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        nameVideoUpdateCallWithRequestBuilder(type: type, id: id, updateCallRequest: updateCallRequest)
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
     Update Call
     - PATCH /call/{type}/{id}
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
     - parameter updateCallRequest: (body)
     - returns: RequestBuilder<UpdateCallResponse>
     */
    internal class func nameVideoUpdateCallWithRequestBuilder(
        type: String,
        id: String,
        updateCallRequest: UpdateCallRequest
    ) -> RequestBuilder<UpdateCallResponse> {
        var localVariablePath = "/call/{type}/{id}"
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
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: updateCallRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<UpdateCallResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
            .getBuilder()

        return localVariableRequestBuilder.init(
            method: "PATCH",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }

    /**
     Query call members
     
     - parameter queryMembersRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func queryMembers(
        queryMembersRequest: QueryMembersRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: QueryMembersResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        queryMembersWithRequestBuilder(queryMembersRequest: queryMembersRequest).execute(apiResponseQueue) { result in
            switch result {
            case let .success(response):
                completion(response.body, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

    /**
     Query call members
     - POST /call/members
     - Query call members with filter query
     - API Key:
       - type: apiKey Authorization
       - name: JWT
     - API Key:
       - type: apiKey api_key (QUERY)
       - name: api_key
     - API Key:
       - type: apiKey Stream-Auth-Type
       - name: stream-auth-type
     - parameter queryMembersRequest: (body)
     - returns: RequestBuilder<QueryMembersResponse>
     */
    internal class func queryMembersWithRequestBuilder(queryMembersRequest: QueryMembersRequest)
        -> RequestBuilder<QueryMembersResponse> {
        let localVariablePath = "/call/members"
        let localVariableURLString = OpenAPIClientAPI.basePath + localVariablePath
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: queryMembersRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<QueryMembersResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
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
