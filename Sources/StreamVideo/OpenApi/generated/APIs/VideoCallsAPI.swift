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
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func getCallEdgeServer(
        type: String,
        id: String,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: GetCallEdgeServerResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        getCallEdgeServerWithRequestBuilder(type: type, id: id).execute(apiResponseQueue) { result in
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
     - POST /get_call_edge_server/{type}/{id}
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
     - returns: RequestBuilder<GetCallEdgeServerResponse>
     */
    internal class func getCallEdgeServerWithRequestBuilder(type: String, id: String) -> RequestBuilder<GetCallEdgeServerResponse> {
        var localVariablePath = "/get_call_edge_server/{type}/{id}"
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
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func getOrCreateCall(
        type: String,
        id: String,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: GetOrCreateCallResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        getOrCreateCallWithRequestBuilder(type: type, id: id).execute(apiResponseQueue) { result in
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
     - returns: RequestBuilder<GetOrCreateCallResponse>
     */
    internal class func getOrCreateCallWithRequestBuilder(type: String, id: String) -> RequestBuilder<GetOrCreateCallResponse> {
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
        let localVariableParameters: [String: Any]? = nil

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
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func joinCall(
        type: String,
        id: String,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: JoinCallResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        joinCallWithRequestBuilder(type: type, id: id).execute(apiResponseQueue) { result in
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
     - returns: RequestBuilder<JoinCallResponse>
     */
    internal class func joinCallWithRequestBuilder(type: String, id: String) -> RequestBuilder<JoinCallResponse> {
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
        let localVariableParameters: [String: Any]? = nil

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

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
}
