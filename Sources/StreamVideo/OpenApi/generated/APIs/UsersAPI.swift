//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal class UsersAPI {

    /**
     Video Connect (WebSocket)
     
     - parameter videoWSAuthMessageRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func videoConnect(
        videoWSAuthMessageRequest: VideoWSAuthMessageRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: Void?, _ error: Error?) -> Void)
    ) -> RequestTask {
        videoConnectWithRequestBuilder(videoWSAuthMessageRequest: videoWSAuthMessageRequest).execute(apiResponseQueue) { result in
            switch result {
            case .success:
                completion((), nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

    /**
     Video Connect (WebSocket)
     - GET /video/connect
     - Establishes WebSocket connection for user
     - API Key:
       - type: apiKey Authorization
       - name: JWT
     - API Key:
       - type: apiKey api_key (QUERY)
       - name: api_key
     - API Key:
       - type: apiKey Stream-Auth-Type
       - name: stream-auth-type
     - parameter videoWSAuthMessageRequest: (body)
     - returns: RequestBuilder<Void>
     */
    internal class func videoConnectWithRequestBuilder(videoWSAuthMessageRequest: VideoWSAuthMessageRequest)
        -> RequestBuilder<Void> {
        let localVariablePath = "/video/connect"
        let localVariableURLString = OpenAPIClientAPI.basePath + localVariablePath
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: videoWSAuthMessageRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<Void>.Type = OpenAPIClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return localVariableRequestBuilder.init(
            method: "GET",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }
}
